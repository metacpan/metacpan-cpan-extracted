package CGI::Stateless;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = 'v2.0.0';

use parent 'CGI';


# override the initialization behavior so that
# state is NOT maintained between invocations 
sub save_request { }


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

CGI::Stateless - Make CGI.pm stateless for use in persistent environment


=head1 VERSION

This document describes CGI::Stateless version v2.0.0


=head1 SYNOPSIS

 use CGI::Stateless;

 # When new request come in FastCGI-like persistent environment:

 local *STDIN;
 open STDIN, '<', \$stdin or die "open STDIN: $!\n";
 local %ENV = %env;
 local $CGI::Q = CGI::Stateless->new();

 # Now you can AGAIN call CGI.pm methods like CGI::param(), etc.


=head1 DESCRIPTION

Force CGI.pm to parse %ENV and STDIN B<AGAIN> in FastCGI-like persistent script.


=head1 INTERFACE 

Use it just like shown in SYNOPSIS, there no other use.



=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-CGI-Stateless/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-CGI-Stateless>

    git clone https://github.com/powerman/perl-CGI-Stateless.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=CGI-Stateless>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/CGI-Stateless>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-Stateless>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=CGI-Stateless>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/CGI-Stateless>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
