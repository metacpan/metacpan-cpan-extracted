package App::Table2YAML::Loader::HTML;

use common::sense;
use charnames q(:full);
use English qw[-no_match_vars];
use Moo::Role;

our $VERSION = '0.003'; # VERSION

sub load_html {...}

no Moo;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Table2YAML::Loader::HTML - Plugin for I<HTML> tables.

=head1 VERSION

version 0.003

=head1 METHODS

=head2 load_html

=head1 AUTHOR

Ronaldo Ferreira de Lima aka jimmy <jimmy at gmail>.

=cut
