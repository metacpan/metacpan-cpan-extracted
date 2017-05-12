package App::vaporcalc::CmdEngine;
$App::vaporcalc::CmdEngine::VERSION = '0.005004';
use Defaults::Modern;
use App::vaporcalc::Types -types;

use Moo;
use Module::Pluggable
  require     => 1,
  sub_name    => '_subjects',
  search_path => 'App::vaporcalc::Cmd::Subject',
  except      => [
    # stale subject plugins; add to this list when deprecating subjects
    'App::vaporcalc::Cmd::Subject::FlavorType',
  ],
;

has subject_list => (
  # don't make me lazy; tests expect possible warnings during instantiation
  is        => 'ro',
  # .. but re-gen is a reasonable thing to do (rebuild_subject_list)
  writer    => '_set_subject_list',
  isa       => ArrayObj,
  coerce    => 1,
  builder   => sub {
    my ($self) = @_;

    my %subj;
    SUBJ: for my $this_class ($self->_subjects) {
      unless ($this_class->can('_subject')) {
        warn 
          "No '_subject' defined for '$this_class' - ",
          "not added to subject_list";
        next SUBJ
      }

      my $this_subj = $this_class->_subject;

      if (my $prev = $subj{$this_subj}) {
        die "BUG -- subject conflict:\n",
            "Subject '$this_subj' defined by:\n '$prev'\n '$this_class'\n",
            "Cannot build subject_list!"
      }

      $subj{$this_subj} = $this_class;
    }  # SUBJ

    if (my @sorted = sort keys %subj) {
      return \@sorted
    }
    warn
      "No command subjects found in module search path; ",
      "namespace: 'App::vaporcalc::Cmd::Subject'";
    []
  },
);

method rebuild_subject_list {
  $self->_set_subject_list( $self->_build_subject_list )
}

with 'App::vaporcalc::Role::UI::ParseCmd',
     'App::vaporcalc::Role::UI::PrepareCmd';

1;

=pod

=head1 NAME

App::vaporcalc::CmdEngine

=head1 SYNOPSIS

  use App::vaporcalc::CmdEngine;
  my $eng = App::vaporcalc::CmdEngine->new;
  my $help = $eng->prepare_cmd( subject => 'help' );
  # See App::vaporcalc::Role::UI::ParseCmd,
  #     App::vaporcalc::Role::UI::PrepareCmd,
  #     App::vaporcalc::Role::UI::Cmd,
  #     App::vaporcalc::Cmd::Result

=head1 DESCRIPTION

A class containing a valid L</subject_list> for use with
L<vaporcalc(1)> command handler roles; see L</CONSUMES>.

=head2 ATTRIBUTES

=head3 subject_list

The list of valid L<vaporcalc(1)> subjects (as an
L<List::Objects::WithUtils::Array>).

Built by scanning classes in the C<App::vaporcalc::Cmd::Subject::> namespace
via L<Module::Pluggable> and collecting the results of calling their
respective C<_subject> methods, which must return unique strings that can be
transformed into the appropriate class name; see
L<App::vaporcalc::Role::UI::Cmd>.

Command classes without a subject will produce a warning and be omitted from
the C<subject_list>.

=head2 METHODS

=head3 rebuild_subject_list

Rebuilds the L</subject_list> by re-scanning the
C<App::vaporcalc::Cmd::Subject::> namespace.

=head3 search_path

  # Current command module search path:
  $eng->search_path;

  # Replace the current search path(s):
  $eng->search_path( new => 'My::vaporcalc::Cmds' );

  # Add another search path & rebuild our subject_list:
  $eng->search_path( add => 'My::vaporcalc::Toys' );
  $eng->rebuild_subject_list;

Modify the pluggable command module search path.
Imported from L<Module::Pluggable>; see there for details.

After search paths have been modified, L</rebuild_subject_list> must be called
to load the newly-found modules and regenerate the L</subject_list> attribute.

=head2 CONSUMES

L<App::vaporcalc::Role::UI::ParseCmd>

L<App::vaporcalc::Role::UI::PrepareCmd>

L<Module::Pluggable/search_path>

=head1 SEE ALSO

L<App::vaporcalc::Role::UI::Cmd> contains an example command subject in the
SYNOPSIS.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
