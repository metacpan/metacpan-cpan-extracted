package Class::Data::Localize;

use strict qw(vars subs);
use vars qw($VERSION);
$VERSION = '0.0401';

use ReleaseAction ();

sub mk_classdata {
    my ($declaredclass, $attribute, $data) = @_;

    if( ref $declaredclass ) {
        require Carp;
        Carp::croak("mk_classdata() is a class method, not an object method");
    }

    my $accessor = sub {
        my $wantclass = ref($_[0]) || $_[0];

        if(@_==3) {
            my $current = $data;
            $_[2] = ReleaseAction->new( sub { $data = $current } );

            if($wantclass ne $declaredclass){
                return mk_classdata($wantclass,$attribute,$data)->(@_);
            }
        }
        else {
            return mk_classdata($wantclass,$attribute)->(@_)
              if @_>1 && $wantclass ne $declaredclass;
        }
        $data = $_[1] if @_>1;
        return $data;
    };

    my $alias = "_${attribute}_accessor";
    *{$declaredclass.'::'.$attribute} = $accessor;
    *{$declaredclass.'::'.$alias}     = $accessor;
}

1;

__END__

=head1 NAME

Class::Data::Localize - Localizable, inheritable, overridable class data

=head1 SYNOPSIS

  package Prince;
  use base qw(Class::Data::Localize);

  # Set up HomeDir as localizable, inheritable class data.
  Prince->mk_classdata('HomeDir');

  # Declare the location of the home dir for this class.
  Prince->HomeDir('/wooden/house/');

  # Teporary move to
     { Prince->HomeDir('/stone/castle',my $move);
       if(Prince->kiss("princess")) {
          $move->cancel
          # live happy in stone castle until end of time
       }
     };

  print Prince->HomeDir; # back in /wooden/house when no kiss

=head1 DESCRIPTION

This is an alternative to Class::Data::Inheritable with the feature
added, that the class data can be localized, similar to the function
of the keyword C<local>.

=head2 Class Method C<mk_classdata>

This class method works the same way as in C::D::I.

Since version 0.04 it is no longer a requirement to inherit from
C<Class::Data::Localize>, because C<mk_classdata> is usable as a 
class function.

  package Mir;

  { my ($mkcd,$self) = (\&Class::Data::Localize::mk_classdata,__PACKAGE__);
    $mkcd->($self,'attribute1' => 9);
    ...
  }

=head2 Compatibility

It is mostly compatible with C::D::I but attention should on the accessor
parameter list. If an accessor is called with an array as argument list,
than a move to this module will break your code.

   Stuff->DataFile(@args); # make sure @args <= 1 or
                           # unwanted things will happen

=head2 Localize Class Data                    

To localize a value give the accessor a lexical variable as second 
argument. Under the hood this module uses than the function of 
L<ReleaseAction> to provide the feature. It stores in the variable an
ReleaseAction object. This let's cancel the localization before the 
variable goes out of scope. When canceled the localized value becomes 
the new persistent value.

=head1 SEE ALSO

=over 4

=item L<ReleaseAction>

=item L<Class::Data::Inheritable>

=back

=head1 TODO

   * to cancel the localization is untested

=head1 AUTHOR

Original code by Damian Conway.

Maintained by Michael G Schwern until September 2005.

Class::Data::Inheritable is maintained by Tony Bowden.

Derived Class::Data::Localize by Sebastian Knapp

=head1 BUGS

Class::Data::Inheritable and Class::Data::Localize can't be used
together easily. This was an early design decision which is maybe wrong.

Possible more.

Please report any bugs or feature requests to
C<bug-package-subroutine@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyleft 2007-2008 Sebastian Knapp <sk@computer-leipzig.com>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

