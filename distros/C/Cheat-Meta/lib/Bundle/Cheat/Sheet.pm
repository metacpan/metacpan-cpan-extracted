package Bundle::Cheat::Sheet;

use 5.008008;
use strict;
use warnings;

use version 0.77; our $VERSION = qv('0.0.5');

## END MODULE 
1;
__END__

=head1 NAME

Bundle::Cheat::Sheet - Copy-and-paste usage lines for lazy coders

=head1 VERSION

This document describes Bundle::Cheat::Sheet version 0.0.5

=head1 SYNOPSIS

    $ perl -MCPAN -e 'install Bundle::Cheat::Sheet'

=head1 DESCRIPTION

I<No, we don't cheat. And even if we did, I'd never tell you.>
--Tommy Lasorda

This is a collection of "cheat sheets": highly compressed, abbreviated 
documentation for various modules. Each module within the bundle covers a 
top-level namespace or a set of otherwise closely-related modules. 

For each module, a paragraph is given, generally: 

    Some::Module            # Short description
        qw( various exportable symbols if any );
        routine( $placeholder, @arguments );
        $context    = function( @arguments);
        $object->method();

You should be able to copy and paste this into your own code, 
delete what you don't need, and be on your way. 

=head1 CONTENTS

Cheat::Sheet::Test

Cheat::Sheet::Util

=head1 SEE ALSO

=over

=item * L<Cheat::Meta>

=item * L<perlcheat>

=back

=head1 BUGS AND LIMITATIONS

No cheat sheet will teach you anything. It's only a reminder. You B<must> 
consult each module's own full documentation I<at least> before using it. 
I hope. 

=head1 THANKS

=over

=item *

To about 8500 authors who have uploaded about 85,000 modules to the CPAN. 

=back

=head1 AUTHOR

Xiong Changnian  C<< <xiong@cpan.org> >>

=head1 LICENSE

Copyright (C) 2010 Xiong Changnian C<< <xiong@cpan.org> >>

This library and its contents are released under Artistic License 2.0:

L<http://www.opensource.org/licenses/artistic-license-2.0.php>

=cut
