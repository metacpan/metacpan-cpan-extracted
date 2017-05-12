package App::Tangerine::Metadata;
$App::Tangerine::Metadata::VERSION = '0.22';
use strict;
use warnings;
use overload
    '""' => sub {
        no warnings 'uninitialized';
        return $_[0]->type."\0".$_[0]->name."\0".$_[0]->version."\0".$_[0]->file
    },
    'cmp' => sub {
        my ($self, $other) = @_;
        return "$self" cmp "$other"
    };


sub new {
    my $class = shift;
    my %args = @_; 
    bless { %args }, $class
}

sub accessor {
    $_[1]->{$_[0]} = $_[2] ? $_[2] : $_[1]->{$_[0]}
}

sub name { accessor(name => @_) }
sub file { accessor(file => @_) }
sub type { accessor(type => @_) }
sub line { accessor(line => @_) }
sub version { accessor(version => @_) }

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Tangerine::Metadata - A structure to hold the discovered metadata

=head1 SYNOPSIS

  use App::Tangerine::Metadata;
  my $md = App::Tangerine::Metadata->new(
    name => 'Foo',
    file => 'bar.pl',
    type => 'c',
    line => 42,
    version => undef,
  );

=head1 DESCRIPTION

This module is meant for the internal use in L<App::Tangerine>.

=head1 SEE ALSO

L<App::Tangerine>, L<Tangerine>

=head1 AUTHOR

Petr Šabata <contyk@redhat.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015 Petr Šabata

See LICENSE for licensing details.

=cut
