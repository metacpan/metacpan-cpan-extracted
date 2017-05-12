package Apache::BumpyLife;

use strict;
use warnings;
use Config;
use Apache::Constants ();

use constant IS_WIN32 => $Config{'osname'} eq 'MSWin32' ? 1 : 0;

our $VERSION = '0.01';
our $DEBUG;
our $MAX_REQUESTS_PER_CHILD_MIN;
our $MAX_REQUESTS_PER_CHILD_MAX;
our $MAX_REQUESTS_PER_CHILD;
our $REQUESTS_PER_CHILD = 0;

sub set_debug {
    my $class = shift;
    $DEBUG = shift || 0;
}

sub set_max_requests_per_child_min {
    my $class = shift;
    $MAX_REQUESTS_PER_CHILD_MIN = shift;
}

sub set_max_requests_per_child_max {
    my $class = shift;
    $MAX_REQUESTS_PER_CHILD_MAX = shift;
}

sub handler {
    my $r = shift || Apache->request;
    return Apache::Constants::DECLINED() unless $r->is_main();

    # we want to operate in a cleanup handler
    if ($r->current_callback eq 'PerlCleanupHandler') {
        return __PACKAGE__->_exit_if_maxreq($r);
    }
    else {
        __PACKAGE__->add_cleanup_handler($r);
    }

    return Apache::Constants::DECLINED();
}

sub add_cleanup_handler {
    my $class = shift;
    my $r = shift || Apache->request;

    return unless $r;
    return if $r->pnotes('bumpylife_cleanup');
 
   $r->push_handlers(
                      'PerlCleanupHandler',
                      sub { $class->_exit_if_maxreq(shift) }
                     );
    $r->pnotes(bumpylife_cleanup => 1);
}

sub _exit_if_maxreq {
    my $class = shift;
    my $r = shift;

    if ( !$MAX_REQUESTS_PER_CHILD_MIN || !$MAX_REQUESTS_PER_CHILD_MAX ) {
        return Apache::Constants::OK();
    }

    if ( ! defined $MAX_REQUESTS_PER_CHILD ) {
        srand();
        $MAX_REQUESTS_PER_CHILD = $MAX_REQUESTS_PER_CHILD_MIN + 
            int(rand() * ($MAX_REQUESTS_PER_CHILD_MAX - $MAX_REQUESTS_PER_CHILD_MIN));
    }

    $REQUESTS_PER_CHILD++;

    if ( $REQUESTS_PER_CHILD >= $MAX_REQUESTS_PER_CHILD ) {
        $r->warn( sprintf "Terminate by BumpyLife [%s] req:%s",$$,$REQUESTS_PER_CHILD) if $DEBUG;
        if (IS_WIN32) {
            # child_terminate() is disabled in win32 Apache
            CORE::exit(-2);
        }
        else {
            $r->child_terminate();
        }
    }

    return Apache::Constants::OK();
}


1;
__END__

=head1 NAME

Apache::BumpyLife - mod_perl 1.x module for setting random value to MaxRequestsPerChild.

=head1 SYNOPSIS

  # httpd.conf
  PerlModule  Apache::BumpyLife
  <Perl>
    Apache::BumpyLife->set_max_requests_per_child_max(100);
    Apache::BumpyLife->set_max_requests_per_child_min(80);
  </Perl>

  PerlCleanupHandler Apache::BumpyLife

=head1 DESCRIPTION

******************************** NOIICE *******************

   This version is only for httpd 1.3.x and mod_perl 1.x
   series.

   For httpd 2.x / mod_perl 2.x, you can use mod_bumpy_life by hirose-san
   https://github.com/hirose31/ap-mod_bumpy_life

******************************** NOIICE *******************

Apache::BumpyLife is httpd 1.3.x and mod_perl 1.x module for setting random value to 
MaxRequestsPerChild within min and max.

This module can moderate the load when many child process is switched to new one at once.

=head1 API

=over 4

=item * Apache::BumpyLife->set_max_requests_per_child_max

This sets the maximum requests per child process. It's ignored if sets over MaxRequestsPerChild, 

=item * Apache::BumpyLife->set_max_requests_per_child_min

This sets the minimum requests per child process. It's ignored if sets over MaxRequestsPerChild, 

=back

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo {at} gmail.comE<gt>

=head1 SEE ALSO

L<Apache::SizeLimit>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

