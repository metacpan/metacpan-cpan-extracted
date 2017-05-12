package Apache::RegistryFilter;

use strict;
use Apache::RegistryNG;
use Apache::Constants qw(:common);
use Symbol;
use vars qw($Debug @ISA);

@ISA = qw(Apache::RegistryNG);

sub handler ($$) {
  my ($class, $r) = @_ > 1 ? (shift, shift) : (__PACKAGE__, shift);
  $class->SUPER::handler($r->filter_register);
}

sub readscript {
  my $pr = shift;
  my $r = $pr->{r};
  
  # Get a filehandle to the Perl code
  my $fh;
  if (lc $r->dir_config('Filter') eq 'on') {
    my $status;
    ($fh, $status) = $r->filter_input();
    $r->notes('FilterRead' => 'this_time');
    return $status unless $status == OK;
  } else {
    $fh = gensym;
    open $fh, $r->filename or die $!;
  }
  
  local $/;
  return $pr->{'code'} = \(scalar <$fh>);
}

sub run {
  my $pr = shift;
  my $r = $pr->{r};

  # If the script was read & compiled in this child in a previous run,
  # we won't have called filter_input().  Call it now.
  unless ($r->notes('FilterRead') eq 'this_time') {
    $r->filter_input(handle => {}) 
  }

  # We temporarily override the header-sending routines to make them
  # noops.  This lets people leave these methods in their scripts.
  local *Apache::send_http_header = sub {};
  local *Apache::send_cgi_header = sub {};
  $pr->SUPER::run(@_);
}

1;

__END__

=head1 NAME

Apache::RegistryFilter - run Perl scripts in an Apache::Filter chain

=head1 SYNOPSIS

 #in httpd.conf

 PerlModule Apache::RegistryFilter

 # Run the output of scripts through Apache::SSI
 <Files ~ "\.pl$">
  PerlSetVar Filter on
  SetHandler perl-script
  PerlHandler Apache::RegistryFilter Apache::SSI
 </Files>

 # Generate some Perl code using templates, then execute it
 <Files ~ "\.tmpl$">
  PerlSetVar Filter on
  SetHandler perl-script
  PerlHandler YourModule::GenCode Apache::RegistryFilter
 </Files>

=head1 DESCRIPTION

This module is a subclass of Apache::RegistryNG, and contains all of its
functionality.  The only difference between the two is that this
module can be used in conjunction with the Apache::Filter module,
whereas Apache::RegistryNG cannot.

For information on how to set up filters, please see the codumentation
for Apache::Filter.

=head1 INCOMPATIBILITIES

At this point the only changes you might have to make to your Registry
scripts are quite minor and obscure.  That is, unless I haven't
thought of something.  Please let me know if any other changes are needed.

=over 4

=item * Don't call send_fd()

If you call Apache's $r->send_fd($filehandle) method, the output will
be sent directly to the browser instead of filtered through the filter
chain.  This is okay if your script is the last filter in the chain,
but clearly it won't work otherwise.

=back

=head1 CAVEATS

This is a subclass of Apache::RegistryNG, not Apache::Registry (which
is not easily subclassible).  Apache::RegistryNG is supposed to be
functionally equivalent to Apache::Registry, but it's a little less
well-tested.

=head1 SEE ALSO

perl(1), mod_perl(3), Apache::Filter(3)

=head1 AUTHOR

Ken Williams <ken@forum.swarthmore.edu>

=cut
