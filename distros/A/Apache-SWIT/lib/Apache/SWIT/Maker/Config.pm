use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Maker::Config::Page;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(class));

package Apache::SWIT::Maker::Config;
use base 'Class::Singleton', 'Class::Accessor';
use YAML;
use File::Slurp;
use Apache::SWIT::Maker::Conversions;

__PACKAGE__->mk_accessors(qw(root_class app_name root_location
			session_class generators pages));

sub _initial_tree {
	my $mf_str = read_file('Makefile.PL');
	my ($root_class) = ($mf_str =~ /NAME[^\n\']+\'([^\']+)/);
	die "Unable to get root_class from $mf_str" unless $root_class;
	my $rl = lc("/" . $root_class);
	$rl =~ s/::/\//g;

	return {
		root_class => $root_class, 
		app_name => conv_class_to_app_name($root_class),
		root_location => $rl,
		session_class => $root_class . "::Session",
		pages => {},
		generators => [ 'Apache::SWIT::Maker::Generator' ],
	};
}

sub _new_instance {
	my ($class) = @_;
	my $tree = -f 'conf/swit.yaml'
		? YAML::LoadFile('conf/swit.yaml') : $class->_initial_tree;
	return $class->new($tree);
}

sub find_page {
	my ($self, $entry) = @_;
	$entry = lc($entry);
	$entry =~ s/::/\//g;
	my $pages = $self->pages;
	my ($res_n, $res_v);
	while (my ($n, $v) = each %$pages) {
		next unless $n =~ m#$entry#;
		$res_n = $n;
		$res_v = $v;
	}
	return undef unless $res_v;
	return bless($res_v, 'Apache::SWIT::Maker::Config::Page');
}

sub save {
	YAML::DumpFile('conf/swit.yaml', shift());
}

sub create_new_page {
	my ($self, $page_class) = @_;
	my $rc = $self->root_class;
	my $full_class = conv_make_full_class($rc, "UI", $page_class);
	my $entry_point = conv_class_to_entry_point($page_class, $rc);

	my $tt_file = "templates/$entry_point.tt";
	my $entry = {
		class => $full_class,
		entry_points => {
			r => {
				template => $tt_file,
				handler => 'swit_render_handler',
			},
			u => {
				handler => 'swit_update_handler',
			},
		},
	};
	$self->pages->{$entry_point} = $entry;
	return $entry;
}

sub add_startup_class {
	my ($self, $sclass) = @_;
	push @{ $self->{startup_classes} }, $sclass;
	$self->save;
}

sub for_each_url {
	my ($self, $cb) = @_;
	while (my ($n, $v) = each %{ $self->pages }) {
		my $l = $self->root_location . "/$n";
		my $ep = $v->{entry_points};
		if (!$ep) {
			$cb->($l, $n, $v, $v);
			next;
		}
		while (my ($en, $ev) = each %$ep) {
			$cb->("$l/$en", $n, $v, $ev);
		}
	}
}

1;
