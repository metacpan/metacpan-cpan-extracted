package Acme::Damn;

use 5.000;
use strict;
use warnings;

use Exporter;
use DynaLoader  qw( AUTOLOAD );

use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK );

  $VERSION    = '0.08';
  @ISA        = qw( Exporter DynaLoader );
  @EXPORT     = qw( damn                );
  @EXPORT_OK  = qw( bless               );

# ensure we aren't exposed to changes in inherited AUTOLOAD behaviour
*Acme::Damn::AUTOLOAD   = *DynaLoader::AUTOLOAD;


sub import
{
  my  $class    = shift;

  # check the unknown symbols to ensure they are 'safe'
  my  @bad      = grep { /\W/o } @_;
  if ( @bad ) {
    # throw an error message informing the user where the problem is
    my  ( undef, $file , $line )    = caller 0;

    die sprintf( "Bad choice of symbol name%s %s for import at %s line %s\n"
                 , ( @bad == 1 ) ? '' : 's'
                 , join( ', ' , map { qq|'$_'| } @bad ) , $file , $line );
  }

  # remove duplicates from the list of aliases, as well as those symbol
  # names listed in @EXPORT
  #   - we keep @EXPORT_OK in a separate list since they are optionally
  #     requested at use() time
  my  @aliases  = do {  local %_;
                              @_{ @_         } = undef;
                       delete @_{ @EXPORT    };
                         keys %_
                     };

  # 'import' the symbols into the host package
  #   - ensure 'EXPORT_OK' is correctly honoured
  my    %reserved   = map { $_ => 1 } @EXPORT , @EXPORT_OK;
  my    @reserved   = ();
  my  ( $pkg )      = caller 1;
  foreach my $alias ( @aliases ) {
    # if this alias is a reserved symbol as defined by @EXPORT et al.
    # then add it to the list of symbols to export
        $reserved{ $alias }
    and push @reserved , $alias
    and next;

    # otherwise, create an alias for 'damn'
    no strict 'refs';

    *{ $pkg . '::' . $alias } = sub {
        my    $ref                      = shift;
        my  ( undef , $file , $line )   = caller 1;

        # call damn() with the location of where this method was
        # originally called
        &{ __PACKAGE__ . '::damn' }( $ref , $alias , $file , $line );

        # NB: wanted to do something like
        #         goto \&{ __PACKAGE__ . '::damn' };
        #     having set the @_ array appropriately, but this caused a
        #     "Attempt to free unrefernced SV" error that I couldn't solve
        #     - I think it was to do with the @_ array
      };
  }

  # add the known symbols to @_
  splice @_ , 0;  push @_ , $class , @reserved;

  # run the "proper" import() routine
  goto \&Exporter::import;
} # import()


bootstrap Acme::Damn $VERSION;


1;  # end of module
__END__
=pod

=head1 NAME

Acme::Damn - 'Unbless' Perl objects.


=head1 SYNOPSIS

  use Acme::Damn;

  my $ref = ... some reference ...
  my $obj = bless $ref , 'Some::Class';
  
  ... do something with your object ...

     $ref = damn $obj;   # recover the original reference (unblessed)

  ... neither $ref nor $obj are Some::Class objects ...


=head1 DESCRIPTION

B<Acme::Damn> provides a single routine, B<damn()>, which takes a blessed
reference (a Perl object), and I<unblesses> it, to return the original
reference.


=head2 EXPORT

By default, B<Acme::Damn> exports the method B<damn()> into the current
namespace. Aliases for B<damn()> (see below) may be imported upon request.

=head2 Methods

=over 4

=item B<damn> I<object>

B<damn()> accepts a single blessed reference as its argument, and returns
that reference unblessed. If I<object> is not a blessed reference, then
B<damn()> will C<die> with an error.


=item B<bless> I<reference>

=item B<bless> I<reference> [ , I<package> ]

=item B<bless> I<reference> [ , undef ]

Optionally, B<Acme::Damn> will modify the behaviour of C<bless> to
allow the passing of an explicit C<undef> as the target package to invoke
B<damn()>:

    use Acme::Damn  qw( bless );

    my  $obj = ... some blessed reference ...;

    # the following statements are equivalent
    my  $ref = bless $obj , undef;
    my  $ref = damn $obj;

B<NOTE:> The modification of C<bless> is lexically scoped to the current
package, and is I<not> global.


=back


=head2 Method Aliases

Not everyone likes to damn the same way or in the same language, so
B<Acme::Damn> offers the ability to specify any alias on import, provided
that alias is a valid Perl subroutine name (i.e. all characters match C<\w>).

  use Acme::Damn qw( unbless );
  use Acme::Damn qw( foo );
  use Acme::Damn qw( unblessthyself );
  use Acme::Damn qw( recant );

Version 0.02 supported a defined list of aliases, and this has been replaced
in v0.03 by the ability to import any alias for C<damn()>.


=head1 WARNING

Just as C<bless> doesn't call an object's initialisation code, C<damn> doesn't
invoke an object's C<DESTROY> method. For objects that need to be C<DESTROY>ed,
either don't C<damn> them, or call C<DESTROY> before judgement is passed.


=head1 ACKNOWLEDGEMENTS

Thanks to Claes Jacobsson E<lt>claes@surfar.nuE<gt> for suggesting the use of
aliases, and Bo Lindbergh E<lt>blgl@cpan.orgE<gt> for the suggested
modification of C<bless>.


=head1 SEE ALSO

L<bless|perlfunc/bless>, L<perlboot>, L<perltoot>, L<perltooc>, L<perlbot>,
L<perlobj>.


=head1 AUTHOR

Ian Brayshaw, E<lt>ibb@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright 2003-2016 Ian Brayshaw

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
