package CPAN::AutoINC;

use strict;
use CPAN;

our $VERSION = '0.01';

sub new {
    my ($this) = shift;
    my ($class) = ref($this) || $this;

    my $self = bless({}, $class);
    
    return $self;
}

sub CPAN::AutoINC::INC {
    my ($self, $filename) = @_;

    if ($filename =~ /^(.+)\.pm$/) {
	my $module = $1;
	$module =~ s!/!::!g;

	foreach my $m (expand("Module", $module)) {
	    CPAN::Shell->install($m);

	    foreach my $prefix (@INC) {
		my $realfilename = "$prefix/$filename";
		if (-f $realfilename) {
		    my $fh;

		    return $fh if (open ($fh, $realfilename));
		}
	    }
	}
    }

    return undef;
}

BEGIN {
    push (@INC, new CPAN::AutoINC());
};

1;
__END__


=head1 NAME

CPAN::AutoINC - Download and install CPAN modules upon first use

=head1 SYNOPSIS

perl -MCPAN::AutoINC <script>

=head1 ABSTRACT

When CPAN::AutoINC is loaded, it will add itself to @INC and catch any
requests for missing resources.  If a Perl module is requested CPAN
will be queried and, assuming that the module exists on CPAN,
CPAN::Shell will be invoked to install it.  Execution of the script
continues after the requisite module has been installed.

=head1 DESCRIPTION

CPAN::AutoINC is a slightly useful tool designed to streamline the
process of installing all of the modules required by a script.  By
loading the CPAN::AutoINC module (usually via a "-MCPAN::AutoINC"
command-line option), the user is registering a handler that will
catch any attempt to use a module that does not exist on the local
machine.  In this case, the CPAN::Shell module will be invoked to
search for the specified module and, if found, an attempt will be made
to install the module.  If successful, the module will be loaded and
execution will continue as normal.

For example:

perl -MCPAN::AutoINC -MLingua::Num2Word=cardinal -le 'print cardinal("en", 42)'

...will download and install Lingua::Num2Word and Lingua::EN::Num2Word.

perl -MCPAN::AutoINC -MLingua::Num2Word=cardinal -le 'print cardinal("de", 42)'

...will then download and install Lingua::DE::Num2Word (German).

perl -MCPAN::AutoINC -MLingua::Num2Word=cardinal -le 'print cardinal("es", 42)'

...will then download and install Lingua::ES::Numeros (Spanish).

=head1 CAVEATS

=over

=item *

The "CPAN" module must be properly configured to run for the user whom
you plan to be when you execute your scripts.  By default CPAN tends
to install into a system path (e.g., /usr/lib/perl), so you would need
to run your scripts as root for this to work transparently.  However,
you can also configure CPAN for other users by installing a
~/.cpan/CPAN/MyConfig.pm file.  In particular, you may want to
override makepl_arg to add a "PREFIX=~/.cpan/install" setting.

=item *

Make sure that the directory where your Perl modules are installed is
in your @INC by default, either by adding a -I option to your command
line or by seting your $PERL5LIB environmental variable.  This is most
likely only necessary if you are not running your scripts as root.

=item *

If the entire directory structure does not exist the first time you
use CPAN::AutoINC, you may need to run your script twice.  For
example, if your PREFIX is set to "~/.cpan/install" and your
PERL5LIB is set to
"~/.cpan/install/perl5:~/.cpan/install/perl5/site_perl",
~/.cpan/install/perl5/site_perl/5.8.0 and
~/.cpan/install/perl5/site_perl/5.8.0/i686-linux will not be
added to your @INC unless they existed before your module was
installed.  In this case loading of the installed module would fail and
you would need to re-run your script.

=item *

You may wish to configure CPAN to always follow dependencies.  This
can be done by setting your 'prerequisites_policy' option to 'follow'.
However, this doesn't guarantee that all module installations will go
smoothly without human intervention; some installation or test
procedures explicitly prompt the user.

=item *

It seems that the CPAN module itself uses Log::Agent somehow, so you
will likely see this installed as the first module.

=head1 MOTIVATION

The description for the Acme::RemoteINC CPAN module ("Slowest Possible
Module Loading") prompted me to write this module.  The only thing
slower than loading precompiled modules via FTP is loading module
source code from FTP and compiling it.  Except maybe carrier pigeons.

As you can see from the CAVEATS section, there is a fair amount of
set-up work required and it will not work for all modules.  This makes
it relatively useless, especially in a production environment.  But
it's a cool hack, and could potentially be useful under very limited
circumstances.

=head1 AUTHOR

Don Schwarz, E<lt>don@schwarz.nameE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Don Schwarz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
