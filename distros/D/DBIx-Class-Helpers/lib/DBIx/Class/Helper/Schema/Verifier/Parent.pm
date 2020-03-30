package DBIx::Class::Helper::Schema::Verifier::Parent;
$DBIx::Class::Helper::Schema::Verifier::Parent::VERSION = '2.036000';
# ABSTRACT: Verify that the Results and ResultSets have the correct base class

use strict;
use warnings;

use MRO::Compat;
use mro 'c3';

use base 'DBIx::Class::Helper::Schema::Verifier';

sub result_verifiers {
   (
      sub {
         my ($s, $result, $set) = @_;

         my $base_result = $s->base_result;
         my $base_set    = $s->base_resultset;

         die "$result is not a $base_result" unless $result->isa($base_result);
         die    "$set is not a $base_set"    unless    $set->isa($base_set);
      },
      shift->next::method,
   )
}

sub base_result    { 'DBIx::Class::Core'      }
sub base_resultset { 'DBIx::Class::ResultSet' }

1;

__END__

=pod

=head1 NAME

DBIx::Class::Helper::Schema::Verifier::Parent - Verify that the Results and ResultSets have the correct base class

=head1 SYNOPSIS

 package MyApp::Schema;

 __PACKAGE__->load_components('Helper::Schema::Verifier::Parent');

 sub base_result    { 'MyApp::Schema::Result'    }
 sub base_resultset { 'MyApp::Schema::ResultSet' }

=head1 DESCRIPTION

C<DBIx::Class::Helper::Schema::Verifier::Parent> verifies that all of your
results and resultsets use the base class that you specify.

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
