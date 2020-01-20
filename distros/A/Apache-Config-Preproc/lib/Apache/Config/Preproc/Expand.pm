package Apache::Config::Preproc::Expand;
use strict;
use warnings;

=head1 NAME

Apache::Config::Preproc::Expand - base class for preprocessor modules

=head1 DESCRIPTION

=head1 CONSTRUCTOR

    $obj = new($conf, ...) 

The only required argument to the constructor is a reference to the
B<Apache::Config::Preproc> object which controls the preprocessing.  The
default constructor saves this reference in the object and makes it
available via the B<conf> method.  Rest of arguments are specific for
each particular expansion and are ignored by the default constructor.

=cut

sub new {
    my ($class, $conf) = @_;
    bless { _conf => $conf }, $class;
}

=head1 METHODS

=head2 conf

Returns the B<Apache::Config::Preproc> object which controls the
preprocessing.  The module can use it in order to inspect the configuration
parse tree.

=cut

sub conf { $_[0]->{_conf} };

=head2 begin_section

    $obj->begin_section($section);

Invoked before running preprocessor expansions on a section.  The section
(an instance of B<Apache::Admin::Config::Tree> or a derived class) is
passed as the argument.

Default implementation is a no-op.

=cut

sub begin_section {}

=head2 end_section

    $obj->end_section($section);

Invoked when all preprocessor expansions are finished for a section.  The
section (an instance of B<Apache::Admin::Config::Tree> or a derived class) is
passed as the argument.

Default implementation is a no-op.

=cut

sub end_section {}

=head2 expand

    $result = $obj->expand($node, \@items);

Expands the configuration tree node B<$node>, places the resulting
nodes to B<@items> and returns true.  Returns false if no expansion
was done on the node.

=cut

sub expand {}

1;

