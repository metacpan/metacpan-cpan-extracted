package Apache::PerlRunFilter;

use strict;
use Apache::PerlRun;
use Apache::Constants qw(:common);
use Symbol;
use vars qw($Debug @ISA);

@ISA = qw(Apache::PerlRun);


sub readscript {
  my $pr = shift;
  
  my $fh = $pr->{'fh'};
  local $/;
  return $pr->{'code'} = \(scalar <$fh>);
}

sub handler {
    my ($package, $r) = @_;
    ($package, $r) = (__PACKAGE__, $package) unless $r;
    my $pr = $package->new($r);
    my $rc = $pr->can_compile;
    return $rc unless $rc == OK;

    # Get a filehandle to the Perl code
    if (lc $r->dir_config('Filter') eq 'on') {
      $r = $r->filter_register;
      my ($fh, $status) = $r->filter_input();
      return $status unless $status == OK;
      $pr->{'fh'} = $fh;
    } else {
      $pr->{'fh'} = gensym;
      open $pr->{'fh'}, $r->filename or die $!;
    }

    # After here is the same as PerlRun.pm...

    my $package = $pr->namespace;
    my $code = $pr->readscript;
    $pr->parse_cmdline($code);

    $pr->set_script_name;
    $pr->chdir_file;
    my $line = $pr->mark_line;
    my %orig_inc = %INC;
    my $eval = join '',
		    'package ',
		    $package,
		    ';use Apache qw(exit);',
                    $line,
		    $$code,
                    "\n";
    $rc = $pr->compile(\$eval);

    $pr->chdir_file("$Apache::Server::CWD/");
    #in case .pl files do not declare package ...;
    for (keys %INC) {
	next if $orig_inc{$_};
	next if /\.pm$/;
	delete $INC{$_};
    }

    if(my $opt = $r->dir_config("PerlRunOnce")) {
	$r->child_terminate if lc($opt) eq "on";
    }

    {   #flush the namespace
	no strict;
	my $tab = \%{$package.'::'};
        foreach (keys %$tab) {
	    if(defined &{$tab->{$_}}) {
		undef_cv_if_owner($package, \&{$tab->{$_}});
	    } 
	}
	%$tab = ();
    }

    return $rc;
}

sub undef_cv_if_owner {
    return unless $INC{'B.pm'};
    my($package, $cv) = @_;
    my $obj    = B::svref_2object($cv);
    my $stash  = $obj->GV->STASH->NAME;
    return unless $package eq $stash;
    undef &$cv;
}


1;

__END__

=head1 NAME

Apache::PerlRunFilter - run Perl scripts in an Apache::Filter chain

=head1 SYNOPSIS

 #in httpd.conf

 PerlModule Apache::PerlRunFilter

 # Run the output of scripts through Apache::SSI
 <Files ~ "\.pl$">
  SetHandler perl-script
  PerlHandler Apache::PerlRunFilter Apache::SSI
  PerlSetVar Filter on
 </Files>

 # Generate some Perl code using templates, then execute it
 <Files ~ "\.tmpl$">
  SetHandler perl-script
  PerlHandler YourModule::GenCode Apache::PerlRunFilter
  PerlSetVar Filter on
 </Files>

=head1 DESCRIPTION

This module is a subclass of Apache::PerlRun, and contains all of its
functionality.  The only difference between the two is that this
module can be used in conjunction with the Apache::Filter module,
whereas Apache::PerlRun cannot.

It only takes a tiny little bit of code to make the filtering stuff
work, so perhaps it would be more appropriate for the code to be
integrated right into Apache::PerlRun.  As it stands, I've had to
duplicate a bunch of PerlRun's code here (in the handler routine), so
bug fixes & feature changes must be made both places.

=head1 CAVEATS

Note that this is not an exact replacement for Apache::Registry - it
doesn't do any of the code-caching stuff that Registry does.  It
shouldn't be too hard a task, but for now Registry is still based on
old code, and Doug's plan is to make future versions of Registry by
subclassing PerlRun (see Apache::RegistryNG).  Since this is the case,
I figured I'd hold off on doing any Registry work until things have
moved forward a bit.

=head1 SEE ALSO

perl(1), mod_perl(3), Apache::PerlRun(3)

=head1 AUTHOR

Ken Williams <ken@forum.swarthmore.edu>

=cut
