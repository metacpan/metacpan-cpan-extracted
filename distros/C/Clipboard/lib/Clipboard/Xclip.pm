package Clipboard::Xclip;
use Clipboard;
sub copy {
    my $self = shift;
    my ($input) = @_;
    $self->copy_to_selection($self->favorite_selection, $input);
}
sub copy_to_selection {
    my $self = shift;
    my ($selection, $input) = @_;
    my $cmd = '|xclip -i -selection '. $selection;
    my $r = open my $exe, $cmd or die "Couldn't run `$cmd`: $!\n";
    print $exe $input;
    close $exe or die "Error closing `$cmd`: $!";
}
sub paste {
    my $self = shift;
    for ($self->all_selections) {
        my $data = $self->paste_from_selection($_); 
        return $data if length $data;
    }
    undef
}
sub paste_from_selection {
    my $self = shift;
    my ($selection) = @_;
    my $cmd = "xclip -o -selection $selection|";
    open my $exe, $cmd or die "Couldn't run `$cmd`: $!\n";
    my $result = join '', <$exe>;
    close $exe or die "Error closing `$cmd`: $!";
    return $result;
}
# This ordering isn't officially verified, but so far seems to work the best:
sub all_selections { qw(primary buffer clipboard secondary) }
sub favorite_selection { my $self = shift; ($self->all_selections)[0] }
{
  open my $just_checking, 'xclip -o|' or warn <<'EPIGRAPH';

Can't find the 'xclip' script.  Clipboard.pm's X support depends on it.

Here's the project homepage: http://sourceforge.net/projects/xclip/

EPIGRAPH
}
