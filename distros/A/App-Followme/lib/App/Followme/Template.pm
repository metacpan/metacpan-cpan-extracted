package App::Followme::Template;

use 5.008005;
use strict;
use warnings;
use integer;

use lib '../..';

use Carp;
use App::Followme::FIO;
use App::Followme::Web;

use base qw(App::Followme::ConfiguredObject);

our $VERSION = "2.02";

use constant COMMAND_START => '<!-- ';
use constant COMMAND_END => '-->';

#----------------------------------------------------------------------
# Compile a template into a subroutine which when called fills itself

sub compile {
    my ($pkg, $template) = @_;

    my $self = ref $pkg ? $pkg : $pkg->new();
    my @lines = split(/\n/, $template);

    my $start = <<'EOQ';
sub {
my ($meta, $item, $loop) = @_;
my @text;
my @loop;
@loop = @$loop if defined $loop;
EOQ

    my @mid = $self->parse_code(\@lines);

    my $end .= <<'EOQ';
return join('', @text);
}
EOQ

    my $code = join("\n", $start, @mid, $end);
    my $sub = eval ($code);
    croak $@ unless $sub;

    return $sub;
}

#----------------------------------------------------------------------
# Replace variable references with hashlist fetches

sub encode_expression {
    my ($self, $value) = @_;

    if (defined $value) {
        my $pre = '{$meta->build(\'';
        my $post = '\', $item, \@loop)}';
        $value =~ s/(?<!\\)([\$\@])(\w+)/$1$pre$1$2$post/g;

    } else {
        $value = '';
    }

    return $value;
}

#----------------------------------------------------------------------
# Get the translation of a template command

sub get_command {
    my ($self, $cmd) = @_;

    my $commands = {
                    do => '%%;',
                    for => 'if (%%) { foreach my $item (my @loop = (%%)) {',
                	endfor => '}}',
                    if => 'if (%%) { do {',
                    elsif => '}} elsif (%%) { do {',
                    else => '}} else { do {',
                    endif => '}}',
                    };

    return $commands->{$cmd};
}

#----------------------------------------------------------------------
# Parse the templace source

sub parse_code {
    my ($self, $lines, $command) = @_;

    my @code;
    my @stash;

    while (defined (my $line = shift @$lines)) {
        my ($cmd, $cmdline) = $self->parse_command($line);

        if (defined $cmd) {
            if (@stash) {
                push(@code, 'push @text, <<"EOQ";', @stash, 'EOQ');
                @stash = ();
            }
            push(@code, $cmdline);

            if (substr($cmd, 0, 3) eq 'end') {
                my $startcmd = substr($cmd, 3);
                die "Mismatched block end ($command/$cmd)"
                      if defined $startcmd && $startcmd ne $command;
                return @code;

            } elsif ($self->get_command("end$cmd")) {
                push(@code, $self->parse_code($lines, $cmd));
            }

        } else {
			push(@stash, $self->encode_expression($line));
		}
    }

    die "Missing end (end$command)" if $command;
    push(@code, 'push @text, <<"EOQ";', @stash, 'EOQ') if @stash;

    return @code;
}

#----------------------------------------------------------------------
# Parse a command and its argument

sub parse_command {
    my ($self, $line) = @_;

    my $command_start_pattern = COMMAND_START;
    return unless $line =~ s/$command_start_pattern//;

    my $command_end_pattern = COMMAND_END;
    $line =~ s/$command_end_pattern//;

    my ($cmd, $arg) = split(' ', $line, 2);
    $arg = '' unless defined $arg;

    my $cmdline = $self->get_command($cmd);
    return unless $cmdline;

    $arg = $self->encode_expression($arg);
    $cmdline =~ s/%%/$arg/g;

    return ($cmd, $cmdline);
}

#----------------------------------------------------------------------
# Set the regular expression patterns used to match a command

sub setup {
    my ($self) = @_;

    $self->{command_start_pattern} = '^\s*' . quotemeta(COMMAND_START);
    $self->{command_end_pattern} = '\s*' . quotemeta(COMMAND_END) . '\s*$';

    return;
}

1;

=pod

=encoding utf-8

=head1 NAME

App::Followme::Template - Handle templates and prototype files

=head1 SYNOPSIS

    use App::Followme::Template;
    my $template = App::Followme::Template->new;
    my $render = $template->compile($template_file);
    my $output = $render->($hash);

=head1 DESCRIPTION

This module contains the methods that perform template handling. A Template is a
file containing commands and variables for making a web page. First, the
template is compiled into a subroutine and then the subroutine is called with a
hash as an argument to fill in the variables and produce a web
page.

=head1 METHODS

This module has one public method:

=over 4

=item $sub = $self->compile($template_file);

Compile a template and return the compiled subroutine. A template is a file
containing commands and variables that describe how data is to be represented.
The method returns a subroutine reference, which when called with a metadata
object, returns a web page containing the fields from the metadata substituted
into variables in the template. Variables in the template are preceded by Perl
sigils, so that a link would look like:

    <li><a href="$url">$title</a></li>

=back

=head1 TEMPLATE SYNTAX

Templates support the basic control structures in Perl: "for" loops and
"if-else" blocks. Creating output is a two step process. First you generate a
subroutine from one or more templates, then you call the subroutine with your
data to generate the output.

The template format is line oriented. Commands are enclosed in html comments
(<!-- -->). A command may be preceded by white space. If a command is a block
command, it is terminated by the word "end" followed by the command name. For
example, the "for" command is terminated by an "endfor" command and the "if"
command by an "endif" command.

All lines may contain variables. As in Perl, variables are a sigil character
('$' or '@') followed by one or more word characters. For example, C<$name> or
C<@names>. To indicate a literal character instead of a variable, precede the
sigil with a backslash. When you run the subroutine that this module generates,
you pass it a metadata object. The subroutine replaces variables in the template
with the value in the field built by the metadata object.

If the first non-white characters on a line are the command start string, the
line is interpreted as a command. The command name continues up to the first
white space character. The text following the initial span of white space is the
command argument. The argument continues up to the command end string.

Variables in the template have the same format as ordinary Perl variables,
a string of word characters starting with a sigil character. for example,

    $body @files

are examples of variables. The following commands are supported in templates:

=over 4

=item do

The remainder of the line is interpreted as Perl code.

=item for

Expand the text between the "for" and "endfor" commands several times. The
argument to the "for" command should be an expression evaluating to a list. The
code will expand the text in the for block once for each element in the list.

    <ul>
    <!-- for @files -->
    <li><a href="$url">$title</a></li>
    <!-- endfor -->
    </ul>

=item if

The text until the matching C<endif> is included only if the expression in the
"if" command is true. If false, the text is skipped.

    <div class="column">
    <!-- for @files -->
    <!-- if $count % 20 == 0 -->
    </div>
    <div class="column">
    <!-- endif -->
    $title<br />
    <!-- endfor -->
    </div>

=item else

The "if" and "for" commands can contain an C<else>. The text before the "else"
is included if the expression in the enclosing command is true and the
text after the "else" is included if the "if" command is false or the "for"
command does not execute. You can also place an "elsif" command inside a block,
which includes the following text if its expression is true.

=back

=head1 ERRORS

What to check when this module throws an error

=over 4

=item Couldn't read template

The template is in a file and the file could not be opened. Check the filename
and permissions on the file. Relative filenames can cause problems and the web
server is probably running another account than yours.

=item Unknown command

Either a command was spelled incorrectly or a line that is not a command
begins with the command start string.

=item Missing end

The template contains a command for the start of a block, but
not the command for the end of the block. For example  an "if" command
is missing an "endif" command.

=item Mismatched block end

The parser found a different end command than the begin command for the block
it was parsing. Either an end command is missing, or block commands are nested
incorrectly.

=item Syntax error

The expression used in a command is not valid Perl.

=back

=head1 LICENSE

Copyright (C) Bernie Simon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bernie Simon E<lt>bernie.simon@gmail.comE<gt>

=cut
