package Apache::FakeSSI;

use strict;
use vars qw(@ISA);
use Apache::Constants qw(:common OPT_INCNOEXEC OPT_INCLUDES);
use Symbol;

@ISA = qw(Apache::SSI);

sub ssi_include {
  my ($self, $args) = @_;
  unless (exists $args->{file} or exists $args->{virtual}) {
    return $self->error("No 'file' or 'virtual' attribute found in SSI 'include' tag");
  }
  
  my $subr = $self->find_file($args);
  
  my $fh = gensym;
  open $fh, $subr->filename 
    or return $self->error("Can't open file '@{[$subr->filename()]}' for include");

  if ($subr->allow_options & OPT_INCLUDES) {
    do {local $/=undef; $self->new( scalar(<$fh>), $subr )}->output;
  } else {
    $self->{_r}->send_fd($fh);
  }
  close $fh;
  
  return '';
}

sub ssi_exec {
    my($self, $args) = @_;
    #XXX did we check enough?
    my $r = $self->{_r};
    my $filename = $r->filename;

    if ($r->allow_options & OPT_INCNOEXEC) {
        $self->error("httpd: exec used but not allowed in $filename");
        return "";
    }
    return scalar `$args->{cmd}` if exists $args->{cmd};
    
    unless (exists $args->{cgi}) {
        $self->error("No 'cmd' or 'cgi' argument given to #exec");
        return '';
    }

    # Okay, we're doing <!--#exec cgi=...>
    my $subr = $r->lookup_uri($args->{cgi});
    unless ($subr->status == 200) {
        $self->error("Error including cgi: subrequest returned status '" . $subr->status . "', not 200");
        return '';
    }
    
    # Pass through our own path_info and query_string (does this work?)
    $subr->path_info( $r->path_info );
    $subr->args( scalar $r->args );
    $subr->content_type("application/x-httpd-cgi");
    &_set_VAR($subr, 'DOCUMENT_URI', $r->uri);
    
    my $status = $subr->run;
    return '';
}

1;

__END__

=head1 NAME

Apache::FakeSSI - Implement Server Side Includes in Pure-Perl

=head1 SYNOPSIS

In httpd.conf:

    <Files *.phtml>  # or whatever
    SetHandler perl-script
    PerlHandler Apache::FakeSSI
    </Files>

You must compile mod_perl with PERL_METHOD_HANDLERS=1 (or
EVERYTHING=1) to use Apache::FakeSSI.

=head1 DESCRIPTION

Apache::FakeSSI is a subclass of Apache::SSI.  The difference between
the two is that Apache::SSI uses full-blown Apache subrequests to
implement server-side includes, whereas Apache::FakeSSI uses
pure-perl.  This allows the output of Apache::FakeSSI to pass through
the regular Perl STDOUT, which means it may be filtered using modules
like Apache::Filter.

Please see the Apache::SSI docs for a complete explanation of its
functionality, or the Apache::Filter docs for more information on
filtering the output of one module through another.

=head1 SEE ALSO

mod_include, mod_perl(3), Apache(3), Apache::SSI(3), Apache::Filter(3)

=head1 AUTHOR

Ken Williams ken@mathforum.org

=head1 COPYRIGHT

Copyright (c) 2002 Ken Williams.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut
