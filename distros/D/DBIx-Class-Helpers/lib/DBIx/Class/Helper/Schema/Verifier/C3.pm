package DBIx::Class::Helper::Schema::Verifier::C3;
$DBIx::Class::Helper::Schema::Verifier::C3::VERSION = '2.036000';
# ABSTRACT: Verify that the Results and ResultSets of your Schemata use c3

use strict;
use warnings;

use MRO::Compat;
use mro 'c3';

use base 'DBIx::Class::Helper::Schema::Verifier';

sub result_verifiers {
   (
      sub {
         my ($s, $result, $set) = @_;

         for ($result, $set) {
            my $mro = mro::get_mro($_);
            die "$_ does not use c3, it uses $mro" unless $mro eq 'c3';
         }
      },
      shift->next::method,
   )
}

1;

__END__

=pod

=head1 NAME

DBIx::Class::Helper::Schema::Verifier::C3 - Verify that the Results and ResultSets of your Schemata use c3

=head1 SYNOPSIS

 package MyApp::Schema;

 __PACKAGE__->load_components('Helper::Schema::Verifier::C3');

=head1 DESCRIPTION

C<DBIx::Class::Helper::Schema::Verifier::C3> verifies that all of your results
and resultsets use the C<c3> C<mro>.  If you didn't know this was important
L<you know now|https://blog.afoolishmanifesto.com/posts/mros-and-you>.  Note:
this will probably fail on  your schema because L<DBIx::Class::ResultSet> does
not use C<c3>.

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
