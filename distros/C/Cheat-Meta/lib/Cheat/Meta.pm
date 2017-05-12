package Cheat::Meta;

use 5.008008;
use strict;
use warnings;

use version 0.77; our $VERSION = qv('0.0.5');

## END MODULE 
1;
__END__

=head1 NAME

Cheat::Meta - Copy-and-paste usage lines for lazy coders

=head1 VERSION

This document describes Cheat::Meta version 0.0.5

=head1 SYNOPSIS

    $ perl -MCPAN -e 'install Cheat::Meta'

=head1 DESCRIPTION

I<If a thing is worth having, it's worth cheating for.> 
--W. C. Fields

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

=head2 Files

Each cheat sheet comes in two formats. 
Both are installed into your Perl library as if they were modules,
according to your installer configuration. 

B<lib/Cheat/Sheet/Foo.perl> -
 Plain Perl code suitable for opening in the editor of your choice. 

B<lib/Cheat/Sheet/Foo.pod>  -
 The same content organized as a POD file. 

You can also get the same content in your pager with: 

    perldoc Cheat::Sheet::Foo

=head1 DEVELOPERS

Of course, if you have any interest in module cheat sheets, 
you're developing something in Perl. Check out the cheats. 

If you want to develop cheat sheets themselves, 
kindly check out L<Cheat::Meta::Spec> for the gory details. 

=head1 SEE ALSO

=over

=item * L<Bundle::Cheat::Sheet>

=item * L<Cheat::Sheet::Test>

=item * L<Cheat::Sheet::Util>

=item * L<Cheat::Meta::Spec>

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

Copyright (C) 2010, 2011 Xiong Changnian C<< <xiong@cpan.org> >>

This library and its contents are released under Artistic License 2.0:

L<http://www.opensource.org/licenses/artistic-license-2.0.php>

=cut
