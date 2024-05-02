package Alien::libversion;

use strict;
use warnings;
use parent qw( Alien::Base );

our $VERSION = '1.00';

1;
__END__

 
=pod
 
=encoding UTF-8
 
=head1 NAME
 
Alien::libversion - Alien wrapper for libversion
 
=head1 SYNOPSIS
 
In your Makefile.PL:
 
 use ExtUtils::MakeMaker;
 use Alien::Base::Wrapper ();
 
 WriteMakefile(
   Alien::Base::Wrapper->new('Alien::libversion')->mm_args2(
     # MakeMaker args
     NAME => 'My::XS',
     ...
   ),
 );
 
In your Build.PL:
 
 use Module::Build;
 use Alien::Base::Wrapper qw( Alien::libversion !export );
 
 my $builder = Module::Build->new(
   ...
   configure_requires => {
     'Alien::libversion' => '0',
     ...
   },
   Alien::Base::Wrapper->mb_args,
   ...
 );
 
 $build->create_build_script;


=head1 DESCRIPTION
 
This distribution provides libversion so that it can be used by other
Perl distributions that are on CPAN.  It does this by first trying to
detect an existing install of libversion on your system.  If found it
will use that.  If it cannot be found, the source code will be downloaded
from the internet and it will be installed in a private share location
for the use of other modules.


=head1 SEE ALSO
 
L<Alien>, L<Alien::Base>, L<Alien::Build::Manual::AlienUser>


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Alien-libversion/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Alien-libversion>

    git clone https://github.com/giterlizzi/perl-Alien-libversion.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
