# -*- coding: utf-8 -*-


package Crane::Base;


use strict;
use warnings;
use utf8;
use feature qw( :5.14 );
use open qw( :std :utf8 );
use base qw( Exporter );

use Carp;
use English qw( -no_match_vars );
use IO::Handle;
use Readonly;
use Try::Tiny;


our @EXPORT = (
    @Carp::EXPORT,
    @English::EXPORT,
    @Try::Tiny::EXPORT,
);


sub import {
    
    my ( $class, @isa ) = @_;
    
    my $caller = caller;
    
    strict->import();
    warnings->import();
    utf8->import();
    feature->import(qw( :5.14 ));
    
    if ( scalar @isa ) {
        foreach my $isa ( @isa ) {
            if ( eval "require $isa" ) {
                no strict 'refs';
                push @{ "${caller}::ISA" }, $isa;
            }
        }
    }
    
    $class->export_to_level(1, $caller);
    
    return;
    
}


1;


=head1 NAME

Crane::Base - Minimal base class for Crane projects


=head1 SYNOPSIS

  use Crane::Base;


=head1 DESCRIPTION

Import this package is equivalent to:

  use strict;
  use warnings;
  use utf8;
  use feature qw( :5.14 );
  use open qw( :std :utf8 );
  
  use Carp;
  use English qw( -no_match_vars );
  use IO::Handle;
  use Readonly;
  use Try::Tiny;


=head1 EXAMPLES


=head2 Script usage

  use Crane::Base;
  
  say 'Hello!' or confess($OS_ERROR);


=head2 Package usage

  package Example;
  
  use Crane::Base qw( Exporter );
  
  Readonly::Scalar(our $CONST => 'value');
  
  our @EXPORT = qw(
      &example
      $CONST
  );
  
  sub example {
      say 'This is an example!' or confess($OS_ERROR);
  }
  
  1;


=head1 BUGS

Please report any bugs or feature requests to
L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Crane> or to
L<https://github.com/temoon/crane/issues>.


=head1 AUTHOR

Tema Novikov, <novikov.tema@gmail.com>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2014 Tema Novikov.

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text of the
license in the file LICENSE.


=head1 SEE ALSO

=over

=item * B<RT Cpan>

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Crane>

=item * B<Github>

L<https://github.com/temoon/crane>

=back
