package Catmandu::Fix::marc_paste;

use Catmandu::Sane;
use Catmandu::MARC;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Inlineable';

our $VERSION = '1.171';

has path   => (fix_arg => 1);
has at     => (fix_opt => 1);
has equals => (fix_opt => 1);

sub fix {
    my ($self, $data) = @_;
    my $path  = $self->path;
    my $at    = $self->at;
    my $regex = $self->equals;
    return Catmandu::MARC->instance->marc_paste($data,$path,$at,$regex);
}

1;

__END__

=head1 NAME

Catmandu::Fix::marc_paste - paste a MARC structured field back into the MARC record

=head1 SYNOPSIS

    # Copy a MARC field
    marc_copy(001, fixed001)

    # Change it
    set_fieldfixed001.0.tag,002)

    # Paste it back into the record
    marc_paste(fixed001)


=head1 DESCRIPTION

Paste a MARC stucture created by L<Catmandu::Fix::marc_struc> back at the end of
a MARC record.

=head1 METHODS

=head2 marc_paste(JSON_PATH, [at: MARC+PATH , [equals: REGEX]])

Paste a MARC struct PATH back in the MARC record. By default the MARC structure will
be pasted at the end of the record. Optionally provide an C<at> option to set the
MARC field after which the structure needs to be pasted. Optionally provide a regex
that should match the content of the C<at> field.

    # Paste mycopy at the end of the record
    marc_paste(mycopy)

    # Paste mycopy after the last 300 field
    marc_paste(mycopy, at:300)

    # Paste mycopy after the last 300 field with indicator1 = 1
    marc_paste(mycopy, at:300[1])

    # Paste mycopy after the last 300 field which has an 'a' subfield
    marc_paste(mycopy, at:300a)

    # Paste mycopy after the last 300 field which has an 'a' subfield equal to 'ABC'
    marc_paste(mycopy, at:300a, equals:'^ABC$')

    # Paste mycopy after the last 300 field with all concatinated subfields equal to 'ABC'
    marc_paste(mycopy, at:300, equals:'^ABC$')

=head1 INLINE

This Fix can be used inline in a Perl script:

    use Catmandu::Fix::marc_struc as => 'marc_struc';
    use Catmandu::Fix::marc_paste as => 'marc_paste';

    my $data = { record => ['650', ' ', 0, 'a', 'Perl'] };

    $data = marc_struc($data,'650','subject');
    $data = marc_paste($data,'subject');


=head1 SEE ALSO

=over

=item * L<Catmandu::Fix::marc_copy>

=item * L<Catmandu::Fix::marc_cut>

=back

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
