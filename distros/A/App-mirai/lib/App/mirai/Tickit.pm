package App::mirai::Tickit;
$App::mirai::Tickit::VERSION = '0.003';
use strict;
use warnings;
use utf8;

use Tickit::DSL qw(:async);
use Tickit::Utils qw(substrwidth textwidth);
use App::mirai::Tickit::TabRibbon;
use App::mirai::Tickit::Widget::Logo;
use Future;
use POSIX qw(strftime);

use JSON::MaybeXS;
use File::Spec;

my %widget;

sub user_path { File::Spec->catpath($_[0]->{user_path}, $_[1]) }
sub share_path { File::Spec->catpath($_[0]->{share_path}, $_[1]) }

sub load_styles {
	my ($self) = shift;
	for my $base (qw(user_path share_path)) {
		for my $path (map $self->$base($_), $ENV{TERM} . '.style', 'default.style') {
			if(-r $path) {
				Tickit::Style->load_style_file($path);
				return $self;
			}
		}
	}

	# Fallback styles
	Tickit::Style->load_style(<<'EOF');
Breadcrumb {
 powerline: 1;
 highlight-bg: 238;
}
MenuBar { bg: 'blue'; fg: 'hi-yellow'; rv: 0; highlight-fg: 'black'; }
Menu { bg: '232'; fg: 'white'; rv: 0; }
Table { highlight-bg: '238'; highlight-fg: 'hi-yellow'; highlight-b: 0; }
FileViewer { highlight-b: 0; }
GridBox { col-spacing: 1; }
EOF
	$self
}

sub new { my $class = shift; bless {@_}, $class }

=head2 stack_table

Creates a table representing a stack trace.

Activating a row in this table will open a file viewer for the given
file and line.

=cut

sub stack_table {
	my ($stack) = @_;
	my $tbl;
	my $truncate = sub {
		my ($row, $col, $item) = @_;
		my $def = $tbl->{columns}[$col];
		return $item unless textwidth($item) > $def->{value};
		substrwidth $item, textwidth($item) - $def->{value};
	};
	$tbl = table {
		my ($row, $data) = @_;
		my ($item) = @$data;
		my ($pkg, $file, $line) = @$item;
		add_widgets {
			fileviewer {
			} $file,
			  'tabsize' => 4,
			  line => $line - 1,
			  'parent:label' => $file;
			  'parent:top' => 3,
			  'parent:left' => 3;
		} under => $widget{desktop};
	} data => $stack,
	  item_transformations => [sub {
	  	my ($row, $item) = @_;
		Future->wrap([ @{$item}[1,2] ])
	  } ],
	  failure_transformations => sub { ' ' },
	  view_transformations => [$truncate],
	  columns => [
		{ label => 'File' },
		{ label => 'Line', align => 'right', width => 6 },
	], 'parent:expand' => 1;
}

=head2 future_details

Opens a panel with details of the given L<Future>.

=cut

sub future_details {
	my $f = shift;
	my $elapsed = sprintf '%.3f', $f->elapsed // 0;
	add_widgets {
		vbox {
			gridbox {
				gridrow {
					static 'Type';
					static $f->type;
				};
				gridrow {
					static 'Status';
					static $f->status;
				};
				gridrow {
					static 'Label';
					static $f->label;
				};
				gridrow {
					static 'Elapsed';
					static $elapsed . 's';
				};
				gridrow {
					static 'Created at';
					static $f->created_at;
				};
				gridrow {
					static 'Ready at';
					static $f->ready_at;
				};
			};
			hbox {
				tree {

				} data => [ Deps => [qw(x y z)] ],
				  'parent:expand' => 1
					if $f->type ne 'leaf';
				vbox {
					static 'Creation stack', align => 0.5;
					stack_table($f->creator_stack);
				} 'parent:expand' => 1;
				vbox {
					static 'Marked ready stack', align => 0.5;
					stack_table($f->ready_stack);
				} 'parent:expand' => 1;
			} 'parent:expand' => 1;
		} style => { spacing => 1 },
		  'parent:label' => $f->label . ' (' . $f->status . ', ' . $elapsed . 's)',
		  'parent:top' => 3,
		  'parent:left' => 3,
		  'parent:lines' => 12;
	} under => $widget{desktop}
}

=head2 app_about

Shows the C< About > dialog popup.

=cut

sub app_about {
	my $vbox = shift;
	my ($tw, $th) = map $vbox->window->$_, qw(cols lines);
	my ($w, $h) = (34, 18);
	float {
		my $f = shift;
		frame {
			vbox {
				customwidget {
					App::mirai::Tickit::Widget::Logo->new
				};
				static 'A tool for debugging Futures', align => 0.5, 'parent:expand' => 1;
				hbox {
					static ' ', 'parent:expand' => 1;
					button {
						$f->remove;
					} 'OK';
					static ' ', 'parent:expand' => 1;
				};
			} style => { spacing => 1 };
		} title => '未来',
		  style => {
			linetype => 'single'
		}
	} top => int(($th-$h)/2),
	  left => int(($tw-$w)/2),
	  right => int($tw - ($tw-$w)/2),
	  bottom => int($th - ($th-$h)/2);
}

sub session_path { $_[0]->user_path('last_session') }

=head2 app_menu

Populates menu items.

=cut

sub app_menu {
	my ($self) = @_;
	menubar {
		submenu File => sub {
			menuitem 'Open session' => sub { warn 'open' };
			menuitem 'Save session' => sub {
				my $sp = $self->session_path;
				unlink $sp if -l $sp;
				my $session = { };
				my @win = @{$widget{desktop}->{widgets}};
				for my $widget (@win) {
					my $label = $widget->label;
					$session->{$label} = {
						geometry => [
							map {;
								$widget->window->rect->$_
							} qw(top left lines cols)
						]
					};
				}
				open my $fh, '>', $sp or die $!;
				$fh->print(encode_json($session));
			};
			menuitem 'Save session as...' => sub { warn 'save as' };
			menuspacer;
			menuitem Exit  => sub { tickit->stop };
		};
		submenu Debug => sub {
			menuitem Copy => sub { warn 'copy' };
			menuitem Cut => sub { warn 'cut' };
			menuitem Paste => sub { warn 'paste' };
		};
		menuspacer;
		submenu Help => sub {
			menuitem About => sub {
				app_about(@_);
			};
		};
	};
}

=head2 apply_layout

Sets up the UI.

=cut

sub apply_layout {
	my ($self) = @_;
	vbox {
		floatbox {
			vbox {
				$self->app_menu;
				$widget{desktop} = desktop {
					vbox {
						my $bc = breadcrumb {
						} item_transformations => sub {
							my ($item) = @_;
							return '' if $item->name eq 'Root';
							$item->name
						};
						my $tree = tree {
						} data => [
							Pending => [
								qw(label2 label3 label4)
							],
							Done => [
								qw(label5)
							],
							Failed => [
								qw(label6)
							],
							Cancelled => [
								qw(label7)
							],
							Dependents => [
								needs_all => [
									qw(label2 label4)
								]
							],
						];
						$bc->adapter($tree->position_adapter);
					} 'parent:top' => 3,
					  'parent:left' => 3,
					  'parent:lines' => 5,
					  'parent:label' => 'Dependencies';
					tabbed {
						{ # Cancelled
							my %table;
							for (qw(pending done failed cancelled)) {
								my $type = $_;
								my $tbl;
								my $truncate = sub {
									my ($row, $col, $item) = @_;
									return '' unless defined $item;
									my $def = $tbl->{columns}[$col];
									return $item unless textwidth($item) > $def->{value};
									substrwidth $item, textwidth($item) - $def->{value};
								};
								$table{$type} = $tbl = table {
									my ($row, $data) = @_;
									my $future = $data->[0];
									eval {
										future_details($future); 1
									} or warn ":: $@";
								} failure_transformations => sub { ' ' },
								  view_transformations => [$truncate],
								  item_transformations => [sub {
									my ($row, $f) = @_;
									my $elapsed = $f->elapsed // 0;
									my $ms = sprintf '.%03d', int(1000 * ($elapsed - int($elapsed)));
									Future->wrap([
										$f,
										$f->created_at // '?',
										($type ne 'pending' ? $f->ready_at // '?' : ()),
										($f->type eq 'dependent' ? 'dep' : $f->type),
										strftime('%H:%M:%S', gmtime int $elapsed) . $ms
									]);
								}], columns => [
									{ label => 'Label', transform => [sub { Future->wrap($_[2]->label) }] },
									{ label => 'Created' },
									($type ne 'pending' ? { label => 'Ready' } : ()),
									{ label => 'Type', width => 5 },
									{ label => 'Elapsed', align => 'right', width => 12},
								], 'parent:label' => ucfirst($type) . ' (0)';
							}
							$self->apply_watchers(\%table);
							loop->later($self->watcher_future->curry::done);
						}
					} ribbon_class => 'App::mirai::Tickit::TabRibbon',
					  tab_position => 'top',
					  'parent:label' => 'Futures';
					fileviewer {
					} $self->script,
					  'tabsize' => 4,
					  'parent:label' => $self->script;
				} 'parent:expand' => 1;
			}
		} 'parent:expand' => 1;
		$widget{statusbar} = statusbar { };
	};
	$widget{statusbar}->update_status('OK');
}

sub apply_watchers {
	my ($self, $table) = @_;

	# This is a lookup table for finding the approximate array offset
	# for a given object. It highlights a gap in the L<Adapter::Async>
	# API that I'm not sure how to resolve just at the moment.
	my %fp;
	for my $tbl (values %$table) {
		$tbl->adapter->bus->subscribe_to_event(
			splice => sub {
				my ($ev, $idx, $len, $data) = @_;
				for (@$data) {
					die "Future " . $_->id . " (" . $_->label . ") already listed?" if exists $fp{$_->id};
					$fp{$_->id} = $idx++;
				}
			}
		);
	}

	$self->bus->subscribe_to_event(
		create => sub {
			my ($ev, $f) = @_;
			die "wtf undef?" unless defined $f;
			$table->{$f->status}->adapter->push([$f]);
		},
		label => sub {
			my ($ev, $f) = @_;
			die "wtf undef?" unless defined $f;
			die "label missing entry $f (" . $f->id . ")" unless exists $fp{$f->id};

			# Trigger refresh for this item
			my $task = $table->{$f->status}->adapter->find_from($fp{$f->id}, $f)->then(sub {
				my ($idx) = @_;
				die "have invalid index" unless defined $idx;
				$table->{$f->status}->adapter->modify($idx, $f)
			})->on_fail(sub { warn "failed? @_"});
			$task->on_ready(sub { undef $task });
		},
		ready => sub {
			my ($ev, $f) = @_;
			die "wtf undef?" unless defined $f;
			die "mark missing entry $f (" . $f->label . " is " . $f->id . ") as ready" unless exists $fp{$f->id};
			my $task = $table->{pending}->adapter->find_from(delete $fp{$f->id}, $f)->then(sub {
				my ($idx) = @_;
				die "have invalid index" unless defined $idx;
				$f->status ne 'pending'
				? $table->{pending}->adapter->delete($idx)
				: Future->wrap
			})->then(sub {
				# We've presumably changed status, so we should now be in a different table
				$table->{$f->status}->adapter->push([ $f ]);
			})->on_fail(sub { warn "failed? @_"});
			$task->on_ready(sub { undef $task });
		},
		destroy => sub {
			my ($ev, $f) = @_;
			die "wtf undef?" unless defined $f;
			warn "destroy missing entry" unless exists $fp{$f->id};

			my $task = $table->{$f->status}->adapter->find_from($fp{$f->id}, $f)->on_done(sub {
				my ($idx) = @_;
				$table->{$f->status}->adapter->modify($idx, $f)
#				$table->{$f->status}->expose_row($idx);
			})->on_fail(sub { warn "failed? @_"});
			$task->on_ready(sub { undef $task });
		}
	);
}

sub prepare {
	my ($self) = @_;
	$self->load_styles;
	$self->apply_layout;
	my $path = $self->session_path;
	if(-r $path) {
		open my $fh, '<', $path or die "Unable to open last session $path - $!";
		my $session = decode_json(do { local $/; <$fh> });
		tickit->later(sub {
			my @win = @{$widget{desktop}->{widgets}};
			for my $widget (@win) {
				my $label = $widget->label;
				if(exists $session->{$label}) {
					$widget->window->change_geometry(
						@{$session->{$label}->{geometry}}
					)
				}
			}
			$win[0]->{linked_widgets}{right} = [
				left => $win[1]
			];
			$win[0]->{linked_widgets}{top} = [
				top => $win[1]
			];
		});
	}
	$self
}

sub script { shift->{script} }

sub bus { shift->{bus} }

sub watcher_future { shift->{watcher_future} ||= loop->new_future->set_label('watcher_future') }

sub run { tickit->run }

1;

