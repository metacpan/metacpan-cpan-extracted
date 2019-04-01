package Acme::Cow;

use strict;

$Acme::Cow::VERSION = '0.1';

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

# Below is stub documentation for your module. You better edit it!

=head1 NAME

Acme::Cow - Talking barnyard animals (or ASCII art in general)

=head1 SYNOPSIS

  use Acme::Cow;

  $cow = new Acme::Cow;
  $cow->say("Moo!");
  $cow->print();

  $sheep = new Acme::Cow::Sheep;	# Derived from Acme::Cow
  $sheep->wrap(20);
  $sheep->think();
  $sheep->text("Yeah, but you're taking the universe out of context.");
  $sheep->print(\*STDERR);

  $duck = new Acme::Cow(File => "duck.cow");
  $duck->fill(0);
  $duck->say(`figlet quack`);
  $duck->print($socket);


=head1 DESCRIPTION

Acme::Cow is the logical evolution of the old cowsay program.  Cows
are derived from a base class (Acme::Cow) or from external files.

Cows can be made to say or think many things, optionally filling
and justifying their text out to a given margin,

Cows are nothing without the ability to print them, or sling them
as strings, or what not.

=cut

use Acme::Cow::TextBalloon;
use IO::File;
use Text::Template;

$Acme::Cow::default_cow = <<'EOC';
{$balloon}
        {$tl}   ^__^
         {$tl}  ({$el}{$er})\_______
            (__)\       )\/\
             {$U} ||----w |
                ||     ||
EOC

=pod

=head1 METHODS

=head2 new

=over 4

=item Parameters

A list of key-value pairs.  If you plan to use an external file as
the template, you probably want to say:

	$x = new Acme::Cow(File => 'file.cow');

=item Returns

A blessed reference to an C<Acme::Cow>.

=back

=cut

sub new 
{
    my $proto = shift;
    my $class = ref $proto || $proto;
    my %args = @_;
    my $self = {
	wrap => 40,
	mode => 'say',
	fill => 1,
	over => 0,
	text => undef,
	el => 'o',
	er => 'o',
	U => '  ',
	%args,
    };
    bless $self, $class;
}

=pod

=head2 over

Specify (or retrieve) how far to the right (in spaces) the text
balloon should be shoved.

=over 4

=item Parameters

(optional) A number.

=item Returns

The new value, if set; the existing value if not.

=back

=cut

sub over
{
    my $self = shift;
    if (@_) {
	$self->{'over'} = $_[0];
    }
    return $self->{'over'};
}

=pod

=head2 wrap

Specify (or retrieve) the column at which text inside the balloon
should be wrapped.  This number is relative to the balloon, not
absolute screen position.

=over 4

=item Parameters

(optional) A number.

=item Returns

The new value, if set; the existing value if not.

=item Notes

The number set here has no effect if you decline filling/adjusting
of the balloon text.

=back

=cut

sub wrap 
{
    my $self = shift;
    if (@_) {
	$self->{'wrap'} = $_[0];
    }
    return $self->{'wrap'};
}

=pod

=head2 think

Tell the cow to think its text instead of saying it.

=over 4

=item Parameters

(optional) Text to think.

=item Returns

None.

=back

=cut

sub think 
{
    my $self = shift;
    $self->{'mode'} = 'think';
    if (@_) {
	$self->text(@_);
    }
}

=pod

=head2 SAY

Tell the cow to say its text instead of thinking it.

=over 4

=item Parameters

(optional) Text to say.

=item Returns

None.

=back

=cut

sub say 
{
    my $self = shift;
    $self->{'mode'} = 'say';
    if (@_) {
	$self->text(@_);
    }
}

=pod

=head2 text

Set (or retrieve) the text that the cow will say or think.

=over 4

=item Parameters

A list of lines of text (optionally terminated with newlines) to
be displayed inside the balloon.

=item Returns

The new text, if set; the current text, if not.

=back

=cut

sub text
{
    my $self = shift;
    if (@_) {
	my @l = @_;
	$self->{'text'} = \@l;
    }
    return $self->{'text'};
}

=pod

=head2 print

Print a representation of the cow to the specified filehandle
(STDOUT by default).

=over 4

=item Parameters

(optional) A filehandle.

=item Returns

None.

=back

=cut

sub print 
{
    my $self = shift;
    my $fh = shift || \*STDOUT;
    print $fh $self->as_string();
}

=pod

=head2 fill

Inform the cow to fill and adjust (or not) the text inside its balloon.
By default, text inside the balloon is filled and adjusted.

=over 4

=item Parameters

(optional) A scalar; true if you want it to fill and adjust, false
otherwise.

=item Returns

The current fill/adjust state, or the new one after setting.

=back

=cut

sub fill 
{
    my $self = shift;
    if (@_) {
	$self->{'fill'} = $_[0];
    }
    return $self->{'fill'};

}

=pod

=head2 as_string

Render the cow as a string.

=over 4

=item Parameters

(optional) A scalar that can be interpreted as a C<STRING> type
for C<Text::Template>.

=item Returns

An ASCII rendering of your cow.

=item Notes

If you're using an external file for a cow template, any difficulties
in processing the file will occur in this method.

Every time this method is called, the result is recalculated; there
is no caching of results.

=back

=cut

sub as_string 
{
    my $self = shift;
    my $tmpl = shift;
    if (not $tmpl) {
	if (defined $self->{'File'}) {
	    $tmpl = _slurp_file($self->{'File'});
	} else {
	    $tmpl = $Acme::Cow::default_cow;
	}
    }
    my $b = $self->_create_balloon();
    my $template = new Text::Template(TYPE => 'STRING', SOURCE => $tmpl);
    chomp($Acme::Cow::_private::balloon = $b->as_string());
    $Acme::Cow::_private::el = $self->{'el'};
    $Acme::Cow::_private::er = $self->{'er'};
    $Acme::Cow::_private::U = $self->{'U'};
    $Acme::Cow::_private::tl = ($self->{'mode'} eq 'think') ? 'o' : '\\';
    $Acme::Cow::_private::tr = ($self->{'mode'} eq 'think') ? 'o' : '/';
    my $text = $template->fill_in(PACKAGE => 'Acme::Cow::_private');
    return $text;
}

sub _create_balloon
{
    my $self = shift;
    my $b = new Acme::Cow::TextBalloon;
    for my $i (qw(fill text over mode wrap)) {
	$b->{$i} = $self->{$i};
    }
    return $b;
}

sub _slurp_file
{
    my $filename = shift;
    my $fh = new IO::File($filename);
    local $/ = undef;
    my $text = $fh->getline();
    return $text;
}

1;
__END__

=pod

=head1 WRITING YOUR OWN COW FILES

First, get comfortable with C<Text::Template> and its capabilities.

{$balloon} is the text balloon; it should be on a line by itself,
flush-left.  {$tl} and {$tr} are what goes to the text balloon from
the thinking/speaking part of the picture; {$tl} is a backslash
("\") for speech, while {$tr} is a slash ("/"); both are a lowercase
letter O ("o") for thought.  {$el} is a left eye, and {$er} is a
right eye; both are "o" by default.  Finally {$U} is a tongue,
because a capital U looks like a tongue.  (Its default value is "U ".) 
Escape all other curly-braces within the ASCII art with backslashes.

There are two methods to make your own cow file: the standalone
file and the Perl module.

For the standalone file, take your piece of ASCII art and modify
it according to the C<Text::Template> rules above.  Note that the
balloon must be flush-left in the template if you choose this method.
If the balloon isn't meant to be flush-left in the final output,
use its C<over()> method.

For a Perl module, you should C<use Text::Template;> and declare
that your module C<ISA> subclass of C<Acme::Cow>.  You may do other
modifications to the variables in the template, if you wish.  You
will most likely need to write appropriate C<new()> and C<as_string()>
methods; many examples are provided with the C<Acme::Cow> distribution.

Put your module somewhere in your C<@INC> path under the C<Acme::Cow::>
tree, and use it like a normal C<Acme::Cow>.  Remember that you
only inherit methods, not data; any data you want to pull out of
C<Acme::Cow> should be accessed explicitly.  Other than that, make
the methods work as expected and you should have a fully functional
cow.

=head1 HISTORY

They're called "cows" because the original piece of ASCII art was
a cow.  Since then, many have been contributed (i.e. the author
has stolen some) but they're still all cows.

=head1 AUTHOR

Tony Monroe E<lt>tmonroe plus perl at nog dot netE<gt>

=head1 SEE ALSO

L<perl>, L<cowsay>, L<figlet>, L<fortune>, L<cowpm>

=cut
