package Catalyst::JobQueue::Job;

use strict;
use warnings;

use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors( 
    qw/ID cronspec user request last_status context env flags scheduler/ 
);

use Carp;
use MRO::Compat;
use Scalar::Util qw/refaddr/;

use version; our $VERSION = qv('0.0.1');

sub DEBUG { $ENV{CATALYST_DEBUG} || 0; }

sub new {
    my ($self, @args) = @_;

    $self = $self->maybe::next::method( @args );
    $self->ID( refaddr($self) );
    $self->flags( {} ) unless $self->flags;
    return $self;
}

sub cleanup
{
    my $self = shift;

    for my $field ( qw/env context/ ) {
        $self->$field( '' );
    }

    $self->flags( {} );
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Catalyst::JobQueue::Job - Catalyst request to be run by a JobQueue Engine


=head1 VERSION

This document describes Catalyst::JobQueue::Job version 0.0.1


=head1 SYNOPSIS

  my $job = $c->engine->get_job($id);

  my $jobid = $job->ID;
 
  
=head1 DESCRIPTION

This object represents a job (i.e. the data needed to build a JobQueue
request). Jobs are created by the engine from various sources. Please do not
attempt to instantiate a job object directly.

=head2 Job Data

Each job object has an ID (currently this is the C<refaddr> of the
hash used to store job data), a set of flags (to signal various stages of job
processing) as well as job type specific data.


=head1 INTERFACE 

=head2 new( \%attr )

Constructs a new job object. Constructor parameters depend on the job type.
C<ID> and C<flags> are filled in automatically.

=head2 cleanup

Clear temporary data, preparing the job for a new run through the engine.

=head2 ID

The ID of the job.

=head2 cronspec

The C<cronspec> string which determines when the job will run.

=head2 user

The user as which the job is to be run. I<UNUSED>.

=head2 request

An array which holds request data. The first element is the request path, the
rest are query arguments (in the form of C<param_name=param_value>).

=head2 last_status

The status code of the last run of the job.

=head2 context

Holds a reference to the current context object.

=head2 env

Holds a reference to the environment hash through which request data is passed
to the engine (CGI-style)

=head2 flags

A set of flags used by the engine in request processing.

=head2 scheduler

A reference to the job's cron scheduler.

=head1 CONFIGURATION AND ENVIRONMENT
 
Catalyst::JobQueue::Job requires no configuration files or environment variables.


=head1 DEPENDENCIES

C<Class::Accessor::Fast>.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-catalyst-jobqueue-job@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Gruen Christian-Rolf  C<< <kiki@bsdro.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Gruen Christian-Rolf C<< <kiki@abc.ro> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.n 1;
