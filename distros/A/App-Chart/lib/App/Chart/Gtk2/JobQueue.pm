# Copyright 2007, 2008, 2009, 2010, 2011, 2016, 2017 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package App::Chart::Gtk2::JobQueue;
use 5.010;
use strict;
use warnings;
use Carp;
use Gtk2;
use Gtk2::Ex::TreeModelBits;

use App::Chart::Glib::Ex::MoreUtils;
use App::Chart;

# uncomment this to run the ### lines
# use Smart::Comments;

use constant DEBUG => 0;

use Glib::Object::Subclass
  'Gtk2::ListStore';

use Class::Singleton 1.03; # 1.03 for _new_instance()
use base 'Class::Singleton';
*_new_instance = \&Glib::Object::new;


# Had some trouble during program exit with Job 'status-changed' emissions
# reaching our _do_job_status_changed() after we have been DESTROY'ed.  This
# must be late in exit since the singleton keeps us alive globally.  But
# it's not at global destruction, according to Devel::GlobalDestruction.
#
# In any case an explicit disconnect of $self->{'hook'} stops the emission.
#
# Normally DESTROY is wrong for Glib::Object subclasses since it's called
# variously when the object loses its last Perl reference but not last C
# reference, or something like that.  But here as a global the last Perl
# reference means program exit.
#
sub DESTROY {
  my ($self) = @_;
  ### JobQueue DESTROY() ...
  undef $self->{'hook'};
  $self->SUPER::DESTROY;
}

sub INIT_INSTANCE {
  my ($self) = @_;
  require App::Chart::Gtk2::Job;
  $self->set_column_types ('App::Chart::Gtk2::Job');

  require App::Chart::Glib::Ex::EmissionHook;
  $self->{'hook'} = App::Chart::Glib::Ex::EmissionHook->new
    ('App::Chart::Gtk2::Job',
     status_changed => \&_do_job_status_changed,
     App::Chart::Glib::Ex::MoreUtils::ref_weak($self));

#   # Left connected until an emission notices the weakening so as to avoid
#   # Glib warnings if we try to remove the hook if already removed during
#   # "global destruction".
#   App::Chart::Gtk2::Job->signal_add_emission_hook
#       ('status_changed', \&_do_job_status_changed,
#        App::Chart::Glib::Ex::MoreUtils::ref_weak($self));
}

sub _do_job_status_changed {
  my ($invocation_hint, $param_list, $ref_weak_self) = @_;
  ### JobQueue _do_job_status_changed() ...

  my ($job) = @$param_list;
  my $self = $$ref_weak_self || return 0; # disconnect
  return if $self->{'destroyed'};

  $self->foreach (sub {
                    my ($self, $path, $iter) = @_;
                    my $j = $self->get_value($iter,0);
                    if ($j == $job) {
                      $self->row_changed ($path, $iter);
                    }
                  });
  return 1; # stay connected
}

sub enqueue {
  my ($self, $job) = @_;
  ref $self or $self = $self->instance;
  $job->isa('App::Chart::Gtk2::Job') or croak "JobQueue: not a job object: $job";

  my $pos = $self->iter_n_children(undef) - 1;
  for ( ; $pos >= 0; $pos--) {
    my $j = $self->get_value ($self->iter_nth_child(undef,$pos), 0);
    if ($j->priority >= $job->priority) {
      last;
    }
  }
  $self->insert_with_values ($pos+1, 0 => $job);
  $self->consider_run ($job);
}

sub consider_run {
  my ($self, $new_job) = @_;
  ref $self or $self = $self->instance;
  my $job = List::Util::first { ! $_->get('done') && ! $_->get('subprocess') }
    $self->all_jobs;
  if (DEBUG) { print "JobQueue next to run ",$job//'undef',"\n"; }

  if ($job) {
    require App::Chart::Gtk2::Subprocess;
    if (my $proc = App::Chart::Gtk2::Subprocess->find_idle) {
      $proc->start_job ($job);
      if ($new_job && $job == $new_job) {
        $new_job = undef;
      }
    }
  }
  if ($new_job) {
    $new_job->set (status => 'Waiting');
  }
}

sub all_jobs {
  my ($self, $job_class) = @_;
  ref $self or $self = $self->instance;
  my @jobs = Gtk2::Ex::TreeModelBits::column_contents ($self, 0);
  if ($job_class) { @jobs = grep { $_->isa($job_class) } @jobs; }
  return @jobs;
}

sub remove_done {
  my ($self) = @_;
  ref $self or $self = $self->instance;
  Gtk2::Ex::TreeModelBits::remove_matching_rows
      ($self, sub { my ($self, $iter) = @_;
                    my $job = $self->get_value ($iter, 0);
                    return $job->get('done');
                  });
}

sub remove_job {
  my ($self, $job) = @_;
  ref $self or $self = $self->instance;
  Gtk2::Ex::TreeModelBits::remove_matching_rows
      ($self, sub { my ($self, $iter) = @_;
                    return $self->get_value($iter,0) == $job;
                  });
}

1;
__END__

=for stopwords JobQueue

=head1 NAME

App::Chart::Gtk2::JobQueue -- queue of job objects

=for test_synopsis my ($job)

=head1 SYNOPSIS

 use App::Chart::Gtk2::JobQueue;
 my $queue = App::Chart::Gtk2::JobQueue->instance;
 App::Chart::Gtk2::JobQueue->enqueue ($job);

=head1 OBJECT HIERARCHY

C<App::Chart::Gtk2::JobQueue> is a subclass of C<Gtk2::ListStore>,

    Glib::Object
      Gtk2::ListStore
        App::Chart::Gtk2::JobQueue

=head1 DESCRIPTION

An C<App::Chart::Gtk2::JobQueue> holds C<App::Chart::Gtk2::Job> objects in a queue while
they wait to run, and then while they run.  The queue is sorted by highest
priority and then by age, with model row 0 begin the next to run, or already
running.

=head1 FUNCTIONS

=over 4

=item C<< $q = App::Chart::Gtk2::JobQueue->instance >>

Return the global JobQueue instance.

=back

=head1 SEE ALSO

L<App::Chart::Gtk2::Job>

=cut
