use strict;
use warnings;

package Text::ZTemplate;

use Carp qw(croak);
use Cwd qw(abs_path);
use Data::ZPath;
use File::Basename qw(dirname);
use File::Spec;

our $VERSION = '0.001000';

sub new {
	my ( $class, %args ) = @_;

	my $string = $args{string};
	my $file = $args{file};

	if ( defined $string and defined $file ) {
		croak q{Specify only one of "string" or "file"};
	}
	if ( not defined $string and not defined $file ) {
		croak q{Missing template source: provide "string" or "file"};
	}

	my $escape = defined $args{escape} ? lc $args{escape} : 'html';
	if ( $escape ne 'html' and $escape ne 'raw' ) {
		croak qq{Invalid escape mode "$escape"};
	}

	if ( defined $file ) {
		( $string, $file ) = _read_template_file($file);
	}

	my $tokens = _parse_template(
		template => $string // q{},
		current_file => $file,
		seen_files => {},
		includes => exists $args{includes} ? $args{includes} : 1,
	);

	my $self = bless {
		escape => $escape,
		tree => $tokens,
	}, $class;

	return $self;
}

sub process {
	my ( $self, $data ) = @_;
	croak 'process() requires a data model' unless defined $data;

	return _render_nodes(
		nodes => $self->{tree},
		context => $data,
		default_escape => $self->{escape},
	);
}

sub _parse_template {
	my ( %args ) = @_;
	my $template = $args{template};
	my $current_file = $args{current_file};
	my $seen_files = $args{seen_files} || {};
	my $includes = $args{includes};

	my $root = [];
	my @stack = ({
		expr => undef,
		nodes => $root,
	});

	my $pos = 0;
	while ( $template =~ /\G(.*?)\{\{/sgc ) {
		my $text = $1;
		if ( length $text ) {
			push @{$stack[-1]{nodes}}, {
				type => 'text',
				text => $text,
			};
		}

		my $tag_start = pos($template) - 2;
		if ( $template !~ /\G(.*?)\}\}/sgc ) {
			croak qq{Unterminated tag at character $tag_start};
		}

		my $raw = $1;
		my $trimmed = $raw;
		$trimmed =~ s/^\s+//;
		$trimmed =~ s/\s+\z//;

		if ( $trimmed =~ /^#(.*)\z/s ) {
			my $inner = $1;
			$inner =~ s/^\s+//;
			$inner =~ s/\s+\z//;
			my $parsed = _parse_expression_spec($inner);
			my $block = {
				type => 'block',
				expr_src => $parsed->{expr},
				expr => Data::ZPath->new( $parsed->{expr} ),
				nodes => [],
			};
			push @{$stack[-1]{nodes}}, $block;
			push @stack, {
				expr => $parsed->{expr},
				nodes => $block->{nodes},
			};
		}
		elsif ( $trimmed =~ m{^/(.*)\z}s ) {
			my $inner = $1;
			$inner =~ s/^\s+//;
			$inner =~ s/\s+\z//;
			my $current = pop @stack;
			if ( not defined $current or not defined $current->{expr} ) {
				croak qq{Mismatched close tag {{/$inner}}};
			}
			if ( length $inner ) {
				my $parsed = _parse_expression_spec($inner);
				if ( $current->{expr} ne $parsed->{expr} ) {
					croak qq{Mismatched close tag {{/$inner}} for {{$current->{expr}}}};
				}
			}
		}
		elsif ( length $trimmed ) {
			if ( $trimmed =~ /^>(.*)\z/s ) {
				croak 'Template includes are disabled'
					unless $includes;

				my $include_path = $1;
				$include_path =~ s/^\s+//;
				$include_path =~ s/\s+\z//;
				croak 'Empty include path in template tag'
					unless length $include_path;

				my $resolved_file = _resolve_include_path(
					include_path => $include_path,
					current_file => $current_file,
				);

				my $key = _canonical_path($resolved_file);
				if ( $seen_files->{$key} ) {
					croak qq{Circular include detected for "$resolved_file"};
				}

				$seen_files->{$key} = 1;
				my ( $include_text, $include_file ) =
					_read_template_file($resolved_file);
				my $include_nodes = _parse_template(
					template => $include_text,
					current_file => $include_file,
					seen_files => $seen_files,
					includes => $includes,
				);
				delete $seen_files->{$key};

				push @{$stack[-1]{nodes}}, @$include_nodes;
			}
			else {
				my $parsed = _parse_expression_spec($trimmed);
				push @{$stack[-1]{nodes}}, {
					type => 'expr',
					expr_src => $parsed->{expr},
					escape => $parsed->{escape},
					expr => Data::ZPath->new( $parsed->{expr} ),
				};
			}
		}

		$pos = pos($template);
	}

	my $tail = substr( $template, $pos );
	if ( length $tail ) {
		push @{$stack[-1]{nodes}}, {
			type => 'text',
			text => $tail,
		};
	}

	if ( @stack > 1 ) {
		my $missing = $stack[-1]{expr};
		croak qq{Missing close tag for {{$missing}}};
	}

	return $root;
}


sub _read_template_file {
	my ( $file ) = @_;

	open my $fh, '<:encoding(UTF-8)', $file
		or croak qq{Unable to read template file "$file": $!};
	local $/;
	my $text = <$fh>;
	close $fh;

	my $canonical = _canonical_path($file);

	return ( $text, $canonical );
}

sub _resolve_include_path {
	my ( %args ) = @_;
	my $include_path = $args{include_path};
	my $current_file = $args{current_file};

	if ( File::Spec->file_name_is_absolute($include_path) ) {
		return $include_path;
	}

	croak qq{Relative include path "$include_path" requires file-based template source}
		unless defined $current_file;

	my $base_dir = dirname($current_file);
	my $resolved = File::Spec->catfile( $base_dir, $include_path );

	return $resolved;
}

sub _canonical_path {
	my ( $path ) = @_;
	my $abs = abs_path($path);
	return defined $abs ? $abs : File::Spec->rel2abs($path);
}

sub _parse_expression_spec {
	my ( $raw ) = @_;
	my $expr = $raw;
	my $escape;

	my $split = _find_escape_separator($raw);
	if ( defined $split ) {
		my ( $lhs, $rhs ) = @$split;
		if ( $rhs eq 'html' or $rhs eq 'raw' ) {
			$expr = $lhs;
			$escape = $rhs;
		}
	}

	$expr =~ s/^\s+//;
	$expr =~ s/\s+\z//;
	croak 'Empty expression in template tag' unless length $expr;

	return {
		expr => $expr,
		escape => $escape,
	};
}

sub _find_escape_separator {
	my ( $text ) = @_;

	my $quote = q{};
	for ( my $i = 0; $i < length $text; $i++ ) {
		my $ch = substr( $text, $i, 1 );
		if ( $quote ) {
			if ( $ch eq '\\' ) {
				$i++;
				next;
			}
			if ( $ch eq $quote ) {
				$quote = q{};
			}
			next;
		}

		if ( $ch eq q{"} or $ch eq q{'} ) {
			$quote = $ch;
			next;
		}

		next unless $ch eq ':';
		next unless substr( $text, $i, 2 ) eq '::';

		my $lhs = substr( $text, 0, $i );
		my $rhs = substr( $text, $i + 2 );
		$lhs =~ s/\s+\z//;
		$rhs =~ s/^\s+//;
		$rhs =~ s/\s+\z//;
		$rhs = lc $rhs;
		return [ $lhs, $rhs ];
	}

	return undef;
}

sub _render_nodes {
	my ( %args ) = @_;
	my $nodes = $args{nodes};
	my $context = $args{context};
	my $default_escape = $args{default_escape};

	my $out = q{};

	for my $node ( @$nodes ) {
		if ( $node->{type} eq 'text' ) {
			$out .= $node->{text};
			next;
		}

		if ( $node->{type} eq 'expr' ) {
			my @vals = $node->{expr}->evaluate( $context );
			my $buf = q{};
			for my $val ( @vals ) {
				my $sv = $val->string_value;
				next unless defined $sv;
				$buf .= $sv;
			}

			my $escape = defined $node->{escape}
				? $node->{escape}
				: $default_escape;
			$out .= _escape( $buf, $escape );
			next;
		}

		if ( $node->{type} eq 'block' ) {
			my @vals = $node->{expr}->evaluate( $context );
			for my $val ( @vals ) {
				next unless _truthy( $val );
				my $inner_context = defined $val->id ? $val : $context;
				$out .= _render_nodes(
					nodes => $node->{nodes},
					context => $inner_context,
					default_escape => $default_escape,
				);
			}
			next;
		}
	}

	return $out;
}

sub _truthy {
	my ( $node ) = @_;
	return !!0 unless $node;
	return !!$node->primitive_value;
}

sub _escape {
	my ( $value, $mode ) = @_;
	return q{} unless defined $value;

	if ( $mode eq 'raw' ) {
		return $value;
	}

	if ( $mode eq 'html' ) {
		$value =~ s/\&/\&amp;/g;
		$value =~ s/\</\&lt;/g;
		$value =~ s/\>/\&gt;/g;
		$value =~ s/"/\&quot;/g;
		$value =~ s/'/\&#39;/g;
		return $value;
	}

	croak qq{Unknown escape mode "$mode"};
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Text::ZTemplate - Mustache-like templates with Data::ZPath

=head1 SYNOPSIS

  use Text::ZTemplate;

  my $template = Text::ZTemplate->new(
    string => q{<h1>{{ product/name }}</h1>},
    escape => 'html',
  );

  my $out = $template->process({
    product => { name => q{A & B} },
  });

=head1 DESCRIPTION

C<Text::ZTemplate> is a small template engine using
L<Data::ZPath> expressions inside C<{{ ... }}> tags.

It supports:

=over

=item *

Substitutions: C<{{ expression }}>

=item *

Blocks/loops/tests:
C<{{# expression }} ... {{/ expression }}>
or C<{{# expression }} ... {{/}}>

=item *

Per-expression escaping override:
C<{{ expression :: html }}> or
C<{{ expression :: raw }}>

=item *

Includes:
C<{{> path/to/include.tmpl }}>
(can be disabled with C<includes =E<gt> 0>)

=back

ZPath expressions are compiled once at template construction
and cached in the template object for reuse across calls to
C<process>.

=head1 METHODS

=head2 C<< new( string => $template, escape => $mode, includes => $bool ) >>

=head2 C<< new( file => $path, escape => $mode, includes => $bool ) >>

Create a compiled template from a UTF-8 string or file.

C<$mode> defaults to C<html>. Valid values are C<html> and
C<raw>.

C<$bool> defaults to true. Set C<includes =E<gt> 0> to
disable support for C<{{> ... }}> tags.

=head2 C<< process( $data ) >>

Apply the template to C<$data> and return the rendered string.

Include paths are resolved relative to the file that contains
that include tag.

=head1 ESCAPING

Default escaping is controlled by C<< new(..., escape => ...) >>.

Individual tags can override the default:

  {{ product/name :: html }}
  {{ product/name :: raw }}

=head1 SEE ALSO

L<Data::ZPath>, L<https://zpath.me/#ztemplate>

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
