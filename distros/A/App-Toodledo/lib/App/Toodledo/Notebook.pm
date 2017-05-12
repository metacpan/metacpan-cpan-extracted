package App::Toodledo::Notebook;
use strict;
use warnings;

our $VERSION = '1.00';

use Carp;
use Moose;
use MooseX::Method::Signatures;
use App::Toodledo::NotebookInternal;
with 'MooseX::Log::Log4perl';

use Moose::Util::TypeConstraints;
BEGIN { class_type 'App::Toodledo' };

extends 'App::Toodledo::InternalWrapper';

has object => ( is => 'ro', isa => 'App::Toodledo::NotebookInternal',
	        default => sub { App::Toodledo::NotebookInternal->new },
	        handles => sub { __PACKAGE__->internal_attributes( $_[1] ) } );


method add ( App::Toodledo $todo! ) {
  my @args = ( name => $self->name );
  $self->$_ and push @args, ( $_ => $self->$_ )
    for qw(title folder private added text);
  my $added_ref = $todo->call_func( notebook => add => { @args } );
  $added_ref->[0]{id};

}


method delete ( App::Toodledo $todo! ) {
  my $id = $self->id;
  my $deleted_ref = $todo->call_func( notebook => delete =>
				      { notebooks => [$id] } );
  $deleted_ref->[0]{id} == $id or $self->log->logdie("Did not get ID back from delete");
}


1;

__END__

=head1 NAME

App::Toodledo::Notebook - class encapsulating a Toodledo notebook

=head1 SYNOPSIS

  $notebook = App::Toodledo::Notebook->new;
  $todo = App::Toodledo->new;
  $todo->add_notebook( $notebook );

=head1 DESCRIPTION

This class provides accessors for the properties of a Toodledo notebook.
The attributes of a notebook are defined in the L<App::Toodledo::NotebookRole>
module.

=head1 AUTHOR

Peter J. Scott, C<< <cpan at psdt.com> >>

=head1 SEE ALSO

Toodledo: L<http://www.toodledo.com/>.

Toodledo API documentation: L<http://www.toodledo.com/info/api_doc.php>.

=head1 COPYRIGHT & LICENSE

Copyright 2009-2011 Peter J. Scott, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
