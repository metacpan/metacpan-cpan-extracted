package App::Followme::Initialize;
use 5.008005;
use strict;
use warnings;

use Cwd;
use IO::File;
use MIME::Base64  qw(decode_base64);
use File::Spec::Functions qw(splitdir catfile);

our $VERSION = "1.94";

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(initialize);

our $var = {};
use constant CMD_PREFIX => '#>>>';

#----------------------------------------------------------------------
# Initialize a new web site

sub initialize {
    my ($directory) = @_;

    chdir($directory) if defined $directory;
    my ($read, $unread) = data_readers();

    while (my ($command, $lines) = next_command($read, $unread)) {
        my @args = split(' ', $command);
        my $cmd = shift @args;

        write_error("Missing lines after command", $command)
            if $cmd eq 'copy' && @$lines == 0;

        write_error("Unexpected lines after command", $command)
            if $cmd ne 'copy' && @$lines > 0;

        if ($cmd  eq 'copy') {
            write_file($lines, @args);

        } elsif ($cmd eq 'set') {
            write_error("No name in set command", $command) unless @args;
            my $name = shift(@args);
            write_var($name, join(' ', @args));

        } else {
            write_error("Error in command name", $command);
        }
    }

    return;
}

#----------------------------------------------------------------------
# Copy a binary file

sub copy_binary {
    my($file, $lines, @args) = @_;

    my $out = IO::File->new($file, 'w') or die "Couldn't write $file: $!\n";
    binmode($out);

    foreach my $line (@$lines) {
        print $out decode_base64($line);
    }

    close($out);
    return;
}

#----------------------------------------------------------------------
# Copy a configuration file

sub copy_configuration {
    my ($file, $lines, @args) = @_;

    my $config_version = shift(@args);
    my $version = read_var('version', $file);
    return unless $version == 0 || $version == $config_version;

    my $configuration = read_var('configuration', $file);
    $lines = merge_configuration($configuration, $lines);

    copy_text($file, $lines, @args);
    return;
}

#----------------------------------------------------------------------
# Copy a text file

sub copy_text {
    my ($file, $lines, @args) = @_;

    my $out = IO::File->new($file, 'w') or die "Couldn't write $file: $!\n";
    foreach my $line (@$lines) {
        print $out $line;
    }

    close($out);
    return;
}

#----------------------------------------------------------------------
# Check path and create directories as necessary

sub create_dirs {
    my ($file) = @_;

    my @dirs = splitdir($file);
    pop @dirs;

    my @path;
    while (@dirs) {
        push(@path, shift(@dirs));
        my $path = catfile(@path);

        if (! -d $path) {
            mkdir($path) or die "Couldn't create $path: $!\n";
            chmod(0755, $path) or die "Couldn't set permissions: $!\n";
        }
    }

    return;
}

#----------------------------------------------------------------------
# Return closures to read the data section of this file

sub data_readers {
    my @pushback;

    my $read = sub {
        if (@pushback) {
            return pop(@pushback);
        } else {
            return <DATA>;
        }
    };

    my $unread = sub {
        my ($line) = @_;
        push(@pushback, $line);
    };

    return ($read, $unread);
}

#----------------------------------------------------------------------
# Get the confoguration file as a list of lines

sub get_configuration {
    my ($file) = @_;
    return read_file($file);
}

#----------------------------------------------------------------------
# Get the configuration file version

sub get_version {
    my ($file) = @_;

    my $configuration = read_var('configuration', $file);
    return 0 unless defined $configuration;

    return read_configuration('version') || 1;
}

#----------------------------------------------------------------------
# Is the line a command?

sub is_command {
    my ($line) = @_;

    my $command;
    my $prefix = CMD_PREFIX;

    if ($line =~ s/^$prefix//) {
        $command = $line;
        chomp $command;
    }

    return $command;
}

#----------------------------------------------------------------------
# Merge new lines into configuration file

sub merge_configuration {
    my ($old_config, $new_config) = @_;

    if ($old_config) {
        my $parser = parse_configuration($new_config);
        my $new_variable = {};
        while (my ($name, $value) = &$parser) {
            $new_variable->{$name} = $value;
        }

        $parser = parse_configuration($old_config);
        while (my ($name, $value) = &$parser) {
            delete $new_variable->{$name} if exists $new_variable->{$name};
        }

        while (my ($name, $value) = each %$new_variable) {
            push(@$old_config, "$name = $value\n");
        }

    } else {
        $old_config = [];
        @$old_config = @$new_config;
    }

    return $old_config;
}

#----------------------------------------------------------------------
# Get the name and contents of the next file

sub next_command {
    my ($read, $unread) = @_;

    my $line = $read->();
    return unless defined $line;

    my $command = is_command($line);
    die "Command not supported: $line" unless $command;

    my @lines;
    while ($line = $read->()) {
        if (is_command($line)) {
            $unread->($line);
            last;

        } else {
            push(@lines, $line);
        }
    }

    return ($command, \@lines);
}

#----------------------------------------------------------------------
# Parse the configuration and return the next name-value pair

sub parse_configuration {
    my ($lines) = @_;
    my @lines = $lines ? @$lines : ();

    return sub {
        while (my $line = shift(@lines)) {
            # Ignore comments and blank lines
            next if $line =~ /^\s*\#/ || $line !~ /\S/;

            # Split line into name and value, remove leading and
            # trailing whitespace

            my ($name, $value) = split (/\s*=\s*/, $line, 2);
            next unless defined $value;
            $value =~ s/\s+$//;

            # Ignore run_before and run_after
            next if $name eq 'run_before' ||
                    $name eq 'run_after' ||
                    $name eq 'module';

            return ($name, $value);
        }

        return;
    };
}

#----------------------------------------------------------------------
# Read a field in the configuration lines

sub read_configuration {
    my ($lines, $field) = @_;

    my $parser = parse_configuration($lines);
    while (my ($name, $value) = &$parser) {
        return $value if $name eq $field;
    }

    return;
}

#----------------------------------------------------------------------
# Read a file as a list of lines

sub read_file {
    my ($file) = @_;

    my $fd = IO::File->new($file, 'r');
    return unless $fd;

    my @lines = <$fd>;
    $fd->close();
    return \@lines;
}

#----------------------------------------------------------------------
# Read the value of a variable

sub read_var {
    my ($name, @args) = @_;

    if (! exists $var->{$name}) {
        no strict;
        my $sub = "get_$name";
        write_var($name, &$sub($var, @args));
    }

    return $var->{$name};
}

#----------------------------------------------------------------------
# Die with error

sub write_error {
    my ($msg, $line) = @_;
    die "$msg: " . substr($line, 0, 30) . "\n";
}

#----------------------------------------------------------------------
# Write a copy of the input file

sub write_file {
    my ($lines, @args) = @_;

    no strict;
    my $type = shift(@args);
    my $file = shift(@args);

    create_dirs($file);

    my $sub = "copy_$type";
    &$sub($file, $lines, @args);

    return;
}

#----------------------------------------------------------------------
# Write the value of a variable

sub write_var {
    my ($name, $value) = @_;

    $var->{$name} = $value;
    return;
}

1;
__DATA__
#>>> copy binary favicon.ico
AAABAAMAEBAAAAEAIABoBAAANgAAACAgAAABACAAKBEAAJ4EAAAwMAAAAQAgAGgmAADGFQAAKAAA
ABAAAAAgAAAAAQAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACWhykx
l4cql5eIK9mXhyv5l4cr+ZeHK9mXhyqWlIQqMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAI2NHAmY
hyual4cr/piILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iIK/2XhimZn38fCAAAAAAAAAAAAAAAAI1x
HAmXiCvBmIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5eHK8Cffx8IAAAA
AAAAAACYhyuamIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/
l4YpmQAAAACWhykxmIgr/ZiILP+YiCz/mosy/7SpaP+bizL/mIgs/5iILP+2q2v/vbN4/5yNNf+Y
iCz/mIgs/5iIK/2UhCowl4cql5iILP+YiCz/mIgs/97Yu//a1LP/5eLM/6OUQ//Uzqn/1c6p/83F
mf/o5dH/oJI+/5iILP+YiCz/l4cqlpeIK9mYiCz/mIgs/6mcUP/Z07L/mIgs/7OnY//6+vb/ycGR
/5iILP+YiCz/tKhm/83Gmv+YiCz/mIgs/5eHK9mXhyv5mIgs/5iILP/CuYT/wLZ//5iILP+YiCz/
7uvd/5yMNP+YiCz/mIgs/6qcUf/X0K3/mIgs/5iILP+Xhyv5l4cr+5iILP+YiCz/0cqh/7OnZf+Y
iCz/mIgs/8rCk/+YiCz/mIgs/5iILP/Hv47/xbyJ/5iILP+YiCz/l4cr95eHK9uYiCz/mIgs/9jS
r/+rnlP/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/7+3g/6ibTv+YiCz/mIgs/5eHKteXhimZmIgs
/5iILP/Vz6v/opRC/5iILP+YiCz/mIgs/5iILP+YiCz/pZdG/+fkz/+YiCz/mIgs/5iILP+WhyqV
locpMZeHK/6YiCz/qJtO/5iJLv+YiCz/mIgs/5iILP+YiCz/mIgs/5iJLf+fkDv/mIgs/5iILP+Y
iCv9l4clLwAAAACXhiqbmIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iI
LP+YiCz/locpmAAAAAAAAAAAjY0cCZeIK8GYiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs
/5iILP+YiCz/l4crwJ9/HwgAAAAAAAAAAAAAAACNjRwJlocrmpiIK/2YiCz/mIgs/5iILP+YiCz/
mIgs/5iILP+YiCv9l4YpmZ9/HwgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACWhykxlocql5eHK9mX
hyv5l4cr+ZeHK9mWhyqXlIQqMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAKAAAACAAAABAAAAAAQAg
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAACZiCIPmYgqWpiHKpyYiCrMl4cr7JeIK/uXhyv7l4cr65eHKsuXhiqblIYoWZF/JA4A
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAACWgicnloYrn5iHK/aYiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs
/5iILP+YiCz/l4gr9ZiHKpyQgiklAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAACZfxkKl4crjZeHK/uYiCz/mIgs/5iILP+YiCz/mIgs/5iILP+Y
iCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5eHK/qXhiqKjXEcCQAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAl4kpJZeHK9SYiCz/mIgs/5iILP+YiCz/mIgs
/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+XhirS
mYMkIwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJOEKDKXhyvrmIgs/5iILP+Y
iCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iI
LP+YiCz/mIgs/5iILP+Xhyvql4crLwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACXgikll4cr
65iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/
mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YhyvpmYokIwAAAAAAAAAAAAAAAAAAAAAA
AAAAmX8ZCpeHK9SYiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iI
LP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+XhirSjXEc
CQAAAAAAAAAAAAAAAAAAAACWhiuOmIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/
mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+Y
iCz/mIgs/5iILP+WhyqLAAAAAAAAAAAAAAAAk4YoJpeHK/qYiCz/mIgs/5iILP+YiCz/mIgs/5iI
LP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs
/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5eHK/qUhiokAAAAAAAAAACXhyuemIgs/5iILP+YiCz/
mIgs/5iILP+YiCz/mIgs/6OVRP/PyJ//1M6p/6SWRf+YiCz/mIgs/5iILP+YiCz/mIgt/8G4gf/q
59X/7uvc/9fRrv+qnVL/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iHKpwAAAAAmYgiD5eH
K/aYiCz/mIgs/5iILP+YiCz/mIgs/5iILP+mmEn/9vTs////////////+Pfx/7Wqaf+YiCz/mIgs
/5qLMv/d2Lv///////v69//29e///v7+//39/P/Fu4j/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/
l4gr9ZF/JA6ZiCpamIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/+Pfx//5+PP/tqtq/7WpZ//t
6tv//f38/8K5hP+aijD/4Nu///v7+P/BuIH/moow/5iILP+om07/4t7F//7+/v+7sHT/mIgs/5iI
LP+YiCz/mIgs/5iILP+YiCz/l4YqWZiHKpyYiCz/mIgs/5iILP+YiCz/mIgs/5iILP+rnlP//v7+
/8e+jf+YiCz/mIgs/5+QOv/u69z//v7+//Hv4//+/v7/t6xs/5iILP+YiCz/mIgs/5iILP+Zii//
5uPN//Px5/+ZiS//mIgs/5iILP+YiCz/mIgs/5iILP+XhiqbmIgrzJiILP+YiCz/mIgs/5iILP+Y
iCz/mIgs/8vDlv/+/v7/opRC/5iILP+YiCz/mIgs/6eZS//9/Pv//////9jTsf+YiCz/mIgs/5iI
LP+YiCz/mIgs/5iILP+5rnD//////6yfVv+YiCz/mIgs/5iILP+YiCz/mIgs/5eHKsyXhyvsmIgs
/5iILP+YiCz/mIgs/5iILP+YiCz/5ODJ//Hv4/+YiCz/mIgs/5iILP+YiCz/mIgs/+vo1//+/v7/
qJtO/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/7SoZv//////tKhl/5iILP+YiCz/mIgs/5iILP+Y
iCz/l4cr7JeHK/yYiCz/mIgs/5iILP+YiCz/mIgs/5iILP/39u//4NzB/5iILP+YiCz/mIgs/5iI
LP+YiCz/5ODI/+zp2f+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/xLuH//////+qnVP/mIgs
/5iILP+YiCz/mIgs/5iILP+Whyv8l4cr/piILP+YiCz/mIgs/5iILP+YiCz/no85///////Uzaj/
mIgs/5iILP+YiCz/mIgs/5iILP/k4cn/0suk/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP/k
4Mn//Pz6/5uLMv+YiCz/mIgs/5iILP+YiCz/mIgs/5iHK/iXhivwmIgs/5iILP+YiCz/mIgs/5iI
LP+pm0///////8rClP+YiCz/mIgs/5iILP+YiCz/mIgs/8i/j/+qnVL/mIgs/5iILP+YiCz/mIgs
/5iILP+YiCz/pZdH//7+/f/n5M//mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/l4cq6JiGKtCYiCz/
mIgs/5iILP+YiCz/mIgs/7CjXf//////wrmD/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+Y
iCz/mIgs/5iILP+YiCz/mIgs/5iILP/Nxpr//////8rCk/+YiCz/mIgs/5iILP+YiCz/mIgs/5iI
LP+XhyvImIgrn5iILP+YiCz/mIgs/5iILP+YiCz/s6dk//////+6r3L/mIgs/5iILP+YiCz/mIgs
/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIkt//Py6P//////qZxQ/5iILP+YiCz/
mIgs/5iILP+YiCz/mIgs/5aHKZiWhildmIgs/5iILP+YiCz/mIgs/5iILP+yp2P//////7KmYf+Y
iCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+sn1X//////+rn
1f+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/l4gpVpaHHhGXhyv3mIgs/5iILP+YiCz/mIgs
/6eaTP//////qZtP/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/
mIgs/7itbv/+/v7/t6xs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5eHK/SJiScNAAAAAJeHK6CY
iCz/mIgs/5iILP+YiCz/mIgs/9rVtf+bjDT/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iI
LP+YiCz/mIgs/5iILP+YiCz/m4wz/7arav+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIcr
mgAAAAAAAAAAloknJ5eHK/uYiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/
mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+Y
iCz/mIgs/5eILPmZgyQjAAAAAAAAAAAAAAAAl4cqj5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iI
LP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs
/5iILP+YiCz/mIgs/5iILP+YiCz/mIcqiQAAAAAAAAAAAAAAAAAAAACZfxkKlocr1ZiILP+YiCz/
mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+Y
iCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5eHKtGffx8IAAAAAAAAAAAAAAAAAAAAAAAA
AACXiSkll4cr65iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs
/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YhyvpmYMkIwAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAACThCgyl4cr65iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+Y
iCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/l4cr6peH
Ky8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACXiSkll4cr1JiILP+YiCz/mIgs
/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/
mIgs/5eHKtKZiisjAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACN
jRwJl4crjZeHK/qYiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iI
LP+YiCz/mIgs/5eHK/qYhyqLjXEcCQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAmoYoJpeHKZ6Xhyv2mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/
mIgs/5iILP+YiCz/mIgs/5eHK/aXhiqdl4kpJQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIh3Ig+WiCpamIcqnJeH
KsyXhyvrl4gr+5eIK/uXhyvrl4cqzJaGKpyXhipZkX8kDgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAKAAAADAAAABgAAAA
AQAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP8AAAGThigTk4YoJpaGKk6WhiiJl4cpt5iH
K9iXhyvvl4cr+5eHKvuXhyrvlocr2ZeHK7eXhimHmYYnTpOGKCaNfyoS//8AAQAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB/fwAEk4QoMpaHK3WX
iCqyl4cr5ZiILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/l4cr/peH
K+aYiCuwlocrdZmJKDKqqgADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAJWDIx2XhiqnmIcr6ZeIK/uYiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+Y
iCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/l4cr+5eHK+qXiCqjkoMmIQAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAACQhSEXlocpdZeHK/OYiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/
mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+Y
iCz/mIcr8ZWGKneWfyIWAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJSDKjyXhyq5l4gs+ZiILP+YiCz/mIgs
/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/
mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5eHK/uXhiu2mIMpPgAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABloUpaZeH
K+yXhyv+mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs
/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+Xhyv+
l4cr7ZaFKGsAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAH9/AAaVhil0l4cr85iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iI
LP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs
/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5eHK/aWhitwf38fCAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAZeGKmyXhyvtmIgs/5iILP+YiCz/mIgs/5iILP+Y
iCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iI
LP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+XhyvsloYr
cAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAmIYpaJeHK/aYiCz/
mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+Y
iCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iI
LP+YiCz/mIgs/5iILP+YiCz/l4cr9paHKGsAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAACZhStBl4cr5ZiILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/
mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+Y
iCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5eHK+2Ygyk+AAAAAQAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAI9/HxCXhyq5l4cr/piILP+YiCz/mIgs/5iILP+YiCz/mIgs
/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/
mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+Y
iCz/mIgs/5eHK/6Xhyu2ln8iFgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJWGKnKXiCv7mIgs/5iI
LP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs
/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/
mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+XiCv7mIYqdwAAAAAAAAAAAAAAAAAAAAAA
AAAAj38nIJeGK/KYiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iI
LP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs
/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/
mIcr8ZeHJyAAAAAAAAAAAAAAAAB/fwAEl4Yqm5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+Y
iCz/mIgs/5iILP+YiCz/mIgs/5qKMf+ll0j/npA6/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iI
LP+YiCz/mIgs/5iILf+omk3/uq9y/7yxdv+ypmL/n5A8/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs
/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5eIKqN/fwAEAAAAAAAAAACVhiY1l4cr4ZiILP+YiCz/
mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/ua5x/+zp2v/19Ov/8e/j/72zef+Y
iCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mYku/8vDlv/08+r/+vr2//v69//49/L/8vDl/8rB
k/+cjTX/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5eHK+qWhygzAAAA
AAAAAAGVhip3l4gs+ZiILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5mJLv/CuIP/
+fjz//////////////////z7+f/MxJj/n5A7/5iILP+YiCz/mIgs/5iILP+klkb/4NvB///////+
/v7//Pz6//v69//9/fz//v7+//7+/f/g28D/p5lL/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iI
LP+YiCz/mIgs/5eHK/uYhyt1f38AApR/KgyXiCqymIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs
/5iILP+YiCz/mIgs/6ueVP/z8eb///////Hv4//f2r7/7erc///////7+/j/2dOz/6WXR/+YiCz/
mIgs/6OUQv/g3MH//f38//n59P/a1LP/xr2L/8G4gv/Lw5b/4t7E//z8+v/+/v7/5uLN/6aZSv+Y
iCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+Xhyuxm38qEpN/JxqXhyromIgs/5iI
LP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/+Hdw//+/v7/7evc/6OVQ/+djTb/oJE9
/8vDlv/9/fv//v79/+zq2/+pnFD/nY44/+fjz//+/f3/9fPr/7CkXv+bjDP/mIgs/5iILP+YiC3/
nY43/7esbf/29e7//v7+/+bizf+cjDX/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+X
hyvnmoYoJpSFJkOYiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/raBX//7+
/v/7+vj/talo/5iILP+YiCz/mIgs/5qLMf/PyJ7//Pv5//7+/v/u7N7/7+zf//7+/v/y8OX/rqJa
/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILf/Atn//+fj0//r69v+6sHP/mIgs/5iILP+YiCz/
mIgs/5iILP+YiCz/mIgs/5iILP+Xhyv+loYnTpeHKYCYiCz/mIgs/5iILP+YiCz/mIgs/5iILP+Y
iCz/mIgs/5iILP+YiCz/08ym///////m4sz/opNA/5iILP+YiCz/mIgs/5iILP+hk0D/3de5////
//////////////v7+P/Eu4f/mYow/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+djjf/497G
//7+/v/Tzaf/m4wz/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/l4gph5iHKrOYiCz/
mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+ejzn/7OnZ//7+/v/QyaD/mYow/5iILP+Y
iCz/mIgs/5iILP+YiCz/n5A7//j48v///////////+3r3P+ejzj/mIgs/5iILP+YiCz/mIgs/5iI
LP+YiCz/mIgs/5iILP+YiCz/x76M///////j38b/oJI+/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs
/5iILP+YiCz/l4cquJeGKtiYiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+toFj/
8/Lo//z7+f/Bt4D/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/+Dcwf///////v7+/7+2fv+Y
iCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/w7qG///////n5M//opRB/5iI
LP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/locr2peHKu+YiCz/mIgs/5iILP+YiCz/mIgs
/5iILP+YiCz/mIgs/5iILP+7sHT/+Pfy//n48/+1qWj/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/
mIgs/9TNp///////9fTs/52OOP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+Y
iCz/z8ie///////k4Mn/oZI//5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/loYr8JaH
K/yYiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP/Hvoz//f37//b17v+qnVL/mIgs
/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/8/Inf//////19Gv/5iILP+YiCz/mIgs/5iILP+YiCz/
mIgs/5iILP+YiCz/mIgs/5iILP+ZiS//5eLM///////b1rb/nY44/5iILP+YiCz/mIgs/5iILP+Y
iCz/mIgs/5iILP+YiCz/loYr/JeHK/6YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5mJ
Lv/QyJ////////Tz6v+ilEH/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/9DJn//+/v7/vLJ4
/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+rnlT/8vHm//7+/v/PyJ7/
mYov/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/l4cr95eHKvWYiCz/mIgs/5iILP+Y
iCz/mIgs/5iILP+YiCz/mIgs/5uLMv/X0a7///////Lw5v+bjDT/mIgs/5iILP+YiCz/mIgs/5iI
LP+YiCz/mIgs/87Hnf/19Oz/qZxR/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs
/5iILf/Eu4b/+/r3//z8+f/Bt4D/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/
l4cq6peHKtyYiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5yNNf/e2Lv//////+3q3P+Y
iCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/6SWRv+4rm//mosx/5iILP+YiCz/mIgs/5iI
LP+YiCz/mIgs/5iILP+YiCz/mIgs/52NNv/f27///v7+//f28P+volv/mIgs/5iILP+YiCz/mIgs
/5iILP+YiCz/mIgs/5iILP+YiCz/l4cq05eHK7eYiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/
mIgs/52OOP/i3sX//////+TgyP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+Y
iCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/6eZS//49/L//////+/t
4f+djjf/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIYqsJaHKYaYiCz/mIgs
/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/56POf/l4sv//////9vVtf+YiCz/mIgs/5iILP+YiCz/
mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+Y
iCz/mIgs/8vDlv///////////9TOqP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iI
LP+YiCz/lYYqg5eFJEWYiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/56POv/n487/////
/9DJov+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/
mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/moow//b07f///////////6ueVP+YiCz/mIgs/5iILP+Y
iCz/mIgs/5iILP+YiCz/mIgs/5iILP+Xhyv+lognR5N/JxqXhyromIgs/5iILP+YiCz/mIgs/5iI
LP+YiCz/mIgs/56POv/n483//////8e/jv+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs
/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/sqZi////////////
6OTR/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+Xhyvhm4YqJJyJJw2Y
hyu1mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/52ON//i3sX//////76zev+YiCz/mIgs/5iI
LP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs
/5iILP+YiCz/xr6M///////7+/j/u7B0/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/
mIgs/5iILP+YiCquloceEQAAAAGXiCt2l4gs+ZiILP+YiCz/mIgs/5iILP+YiCz/mIgs/5uLMv/X
0a7//////7KmYv+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iI
LP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/zMSX//7+/v/e2b3/n5A7/5iILP+YiCz/mIgs
/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5eHK/qYiCtwAAAAAQAAAACWhygzmIcr4JiILP+YiCz/
mIgs/5iILP+YiCz/mIgs/5iILP++tHv/8vHm/6KUQv+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+Y
iCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/oZI//9TO
qP+pm0//mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5eHKuiVhSYuAAAA
AAAAAACZZgAFmIYqnZiILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+cjTX/sKRf/5iILP+YiCz/
mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+Y
iCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iI
LP+YiCz/mIgs/5aGKqGqVQADAAAAAAAAAAAAAAAAl4QlG5eHK/KYiCz/mIgs/5iILP+YiCz/mIgs
/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/
mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+Y
iCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/l4cr75R/HxgAAAAAAAAAAAAAAAAAAAAAAAAAAJaG
KW6Xhyv6mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs
/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/
mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+Xhyv5loYrcAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAI9/HxCWhyq6l4cr/piILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iI
LP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs
/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/
mIgs/5eHK/6Yhyu1nYUkFQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACUgyo8mIcr5JiILP+Y
iCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iI
LP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs
/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5eHKuuZhik3AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAlocpYpeHK/KYiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+Y
iCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iI
LP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/l4Yr8peFKWMAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAZeGKmyXhyvtmIgs/5iILP+YiCz/
mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+Y
iCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iI
LP+XhyvsloYrcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AH9/AASXhipsl4cr8piILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/
mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+Y
iCz/mIgs/5iILP+YiCz/mIgs/5eIK/WVhilomZkABQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABlYYnYZeHKuOYiCv9mIgs/5iILP+YiCz/mIgs
/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/
mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCv9mIcq5JaHK2QAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJeF
KzuXhyq4l4gs+ZiILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs
/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5eIK/uXhyu2
lYUoPwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAACZiCIPlYUqbZiIK/GYiCz/mIgs/5iILP+YiCz/mIgs/5iI
LP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs
/5iILP+YiCz/mIcr8ZaGK3CZiCIPAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJx/JxqX
hiqbmIgr35eHLPmYiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5iI
LP+YiCz/mIgs/5iILP+YiCz/l4gr+ZeHK+GXhimZlIMgHwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAB/fwAElocpMZeGKXSXhiqyl4cr5ZiILP+YiCz/mIgs/5iILP+Y
iCz/mIgs/5iILP+YiCz/mIgs/5iILP+YiCz/mIgs/5eHK+eXhyuxl4grdpaHKDN/fwAEAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGUfyoM
mIQoGZeHJ0CXhyp+l4UpsZiHK9WXhyvtl4cq+peHK/uXhyvtl4cq15eIKrKXhSp+loMmQpiEKBmU
fyoMAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAA==
#>>> copy configuration followme.cfg 0
run_before = App::Followme::FormatPage
run_before = App::Followme::ConvertPage

#>>> copy text index.html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<link rel="shortcut icon" type="image/png" href="favicon.ico"> 
<link rel="stylesheet" id="css_style" href="theme.css">
<!-- section meta -->
<base href="file:///home/bernie/Code/App-Followme/test" />
<title>Test</title>
<meta name="date" content="2016-02-13T07:41:02" />
<meta name="description" content="This is the top page" />
<meta name="keywords" content="" />
<meta name="author" content="" />
<!-- endsection meta -->
</head>
<body>
<header>
<div id="banner">
<h1>Your Site Title</h1>
</div>
<nav>
<label for="hamburger">&#9776;</label>
<input type="checkbox" id="hamburger"/>
<ul>
<li><a href="index.html">Home</a></li>
<li><a href="about.html">About</a></li>
<li><a href="essays.html">Essays</a></li>
</ul>
</nav>
</header>
<article>
<section id="primary">
<!-- section primary -->
<p>
Lorem ipsum dolor <a Href="#">sit amet</a>, consectetur adipiscing elit. 
Fusce vitae malesuada ipsum. Duis sit amet leo metus. 
Vivamus sed libero eleifend, auctor leo non, dignissim tortor. 
Maecenas quam enim, interdum vitae massa non, tincidunt maximus nisi. 
</p>
<p>
Donec ac elit massa. In sed bibendum risus. 
Ut condimentum est nec urna volutpat, quis vehicula elit elementum. 
Quisque molestie auctor ante eu fermentum. 
In hac habitasse platea dictumst. 
</p>
<p>
Suspendisse vehicula dui sed tempor interdum. 
Vestibulum pharetra dolor at felis auctor hendrerit. 
In vel risus dictum, condimentum leo et, tempus magna.
Ut pretium semper mauris, nec mattis eros consequat quis. 
</p>
</section>
<!-- endsection primary-->
<section id="secondary">
<!-- section secondary -->
<!-- endsection secondary-->
</section>
</article>
<footer>
</footer>
</body>
</html>
#>>> copy text menu.css
/* [ON BIG SCREEN] */
/* Wrapper */
header nav {
  width: 100%;
  background: #000;
  /* If you want the navigation bar to stick on top
  position: sticky;
  top: 0;
  */
}

/* Hide Hamburger */
header nav label, #hamburger {
  display: none;
}

/* Menu Items */
header nav ul {
  list-style-type: none;
  margin: 0;
  padding: 0; 
}
header nav ul li {
  display: inline-block;
  padding: 10px;
  box-sizing: border-box;
}
header nav ul li a {
  color: #fff;
  text-decoration: none;
  font-family: arial, sans-serif;
  font-weight: bold;
}

/* [ON SMALL SCREENS] */
@media screen and (max-width: 768px){
  /* Show Hamburger */
  header nav label {
    display: inline-block;
    color: #fff;
    background: #a02620;
    font-style: normal;
    font-size: 1.2em;
    font-weight: bold;
    padding: 10px;
  }

  /* Break down menu items into vertical */
  header nav ul li {
    display: block;
  }
  header nav ul li {
    border-top: 1px solid #333;
  }

  /* Toggle show/hide menu on checkbox click */
  header nav ul {
    display: none;
  }
  header nav input:checked ~ ul {
    display: block;
  }
}

/**
 * Copyright 2019 by Code Boxx
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * /
#>>> copy text normalize.css
/*! normalize.css v8.0.1 | MIT License | github.com/necolas/normalize.css */

/* Document
   ========================================================================== */

/**
 * 1. Correct the line height in all browsers.
 * 2. Prevent adjustments of font size after orientation changes in iOS.
 */

html {
  line-height: 1.15; /* 1 */
  -webkit-text-size-adjust: 100%; /* 2 */
}

/* Sections
   ========================================================================== */

/**
 * Remove the margin in all browsers.
 */

body {
  margin: 0;
}

/**
 * Render the `main` element consistently in IE.
 */

main {
  display: block;
}

/**
 * Correct the font size and margin on `h1` elements within `section` and
 * `article` contexts in Chrome, Firefox, and Safari.
 */

h1 {
  font-size: 2em;
  margin: 0.67em 0;
}

/* Grouping content
   ========================================================================== */

/**
 * 1. Add the correct box sizing in Firefox.
 * 2. Show the overflow in Edge and IE.
 */

hr {
  box-sizing: content-box; /* 1 */
  height: 0; /* 1 */
  overflow: visible; /* 2 */
}

/**
 * 1. Correct the inheritance and scaling of font size in all browsers.
 * 2. Correct the odd `em` font sizing in all browsers.
 */

pre {
  font-family: monospace, monospace; /* 1 */
  font-size: 1em; /* 2 */
}

/* Text-level semantics
   ========================================================================== */

/**
 * Remove the gray background on active links in IE 10.
 */

a {
  background-color: transparent;
}

/**
 * 1. Remove the bottom border in Chrome 57-
 * 2. Add the correct text decoration in Chrome, Edge, IE, Opera, and Safari.
 */

abbr[title] {
  border-bottom: none; /* 1 */
  text-decoration: underline; /* 2 */
  text-decoration: underline dotted; /* 2 */
}

/**
 * Add the correct font weight in Chrome, Edge, and Safari.
 */

b,
strong {
  font-weight: bolder;
}

/**
 * 1. Correct the inheritance and scaling of font size in all browsers.
 * 2. Correct the odd `em` font sizing in all browsers.
 */

code,
kbd,
samp {
  font-family: monospace, monospace; /* 1 */
  font-size: 1em; /* 2 */
}

/**
 * Add the correct font size in all browsers.
 */

small {
  font-size: 80%;
}

/**
 * Prevent `sub` and `sup` elements from affecting the line height in
 * all browsers.
 */

sub,
sup {
  font-size: 75%;
  line-height: 0;
  position: relative;
  vertical-align: baseline;
}

sub {
  bottom: -0.25em;
}

sup {
  top: -0.5em;
}

/* Embedded content
   ========================================================================== */

/**
 * Remove the border on images inside links in IE 10.
 */

img {
  border-style: none;
}

/* Forms
   ========================================================================== */

/**
 * 1. Change the font styles in all browsers.
 * 2. Remove the margin in Firefox and Safari.
 */

button,
input,
optgroup,
select,
textarea {
  font-family: inherit; /* 1 */
  font-size: 100%; /* 1 */
  line-height: 1.15; /* 1 */
  margin: 0; /* 2 */
}

/**
 * Show the overflow in IE.
 * 1. Show the overflow in Edge.
 */

button,
input { /* 1 */
  overflow: visible;
}

/**
 * Remove the inheritance of text transform in Edge, Firefox, and IE.
 * 1. Remove the inheritance of text transform in Firefox.
 */

button,
select { /* 1 */
  text-transform: none;
}

/**
 * Correct the inability to style clickable types in iOS and Safari.
 */

button,
[type="button"],
[type="reset"],
[type="submit"] {
  -webkit-appearance: button;
}

/**
 * Remove the inner border and padding in Firefox.
 */

button::-moz-focus-inner,
[type="button"]::-moz-focus-inner,
[type="reset"]::-moz-focus-inner,
[type="submit"]::-moz-focus-inner {
  border-style: none;
  padding: 0;
}

/**
 * Restore the focus styles unset by the previous rule.
 */

button:-moz-focusring,
[type="button"]:-moz-focusring,
[type="reset"]:-moz-focusring,
[type="submit"]:-moz-focusring {
  outline: 1px dotted ButtonText;
}

/**
 * Correct the padding in Firefox.
 */

fieldset {
  padding: 0.35em 0.75em 0.625em;
}

/**
 * 1. Correct the text wrapping in Edge and IE.
 * 2. Correct the color inheritance from `fieldset` elements in IE.
 * 3. Remove the padding so developers are not caught out when they zero out
 *    `fieldset` elements in all browsers.
 */

legend {
  box-sizing: border-box; /* 1 */
  color: inherit; /* 2 */
  display: table; /* 1 */
  max-width: 100%; /* 1 */
  padding: 0; /* 3 */
  white-space: normal; /* 1 */
}

/**
 * Add the correct vertical alignment in Chrome, Firefox, and Opera.
 */

progress {
  vertical-align: baseline;
}

/**
 * Remove the default vertical scrollbar in IE 10+.
 */

textarea {
  overflow: auto;
}

/**
 * 1. Add the correct box sizing in IE 10.
 * 2. Remove the padding in IE 10.
 */

[type="checkbox"],
[type="radio"] {
  box-sizing: border-box; /* 1 */
  padding: 0; /* 2 */
}

/**
 * Correct the cursor style of increment and decrement buttons in Chrome.
 */

[type="number"]::-webkit-inner-spin-button,
[type="number"]::-webkit-outer-spin-button {
  height: auto;
}

/**
 * 1. Correct the odd appearance in Chrome and Safari.
 * 2. Correct the outline style in Safari.
 */

[type="search"] {
  -webkit-appearance: textfield; /* 1 */
  outline-offset: -2px; /* 2 */
}

/**
 * Remove the inner padding in Chrome and Safari on macOS.
 */

[type="search"]::-webkit-search-decoration {
  -webkit-appearance: none;
}

/**
 * 1. Correct the inability to style clickable types in iOS and Safari.
 * 2. Change font properties to `inherit` in Safari.
 */

::-webkit-file-upload-button {
  -webkit-appearance: button; /* 1 */
  font: inherit; /* 2 */
}

/* Interactive
   ========================================================================== */

/*
 * Add the correct display in Edge, IE 10+, and Firefox.
 */

details {
  display: block;
}

/*
 * Add the correct display in all browsers.
 */

summary {
  display: list-item;
}

/* Misc
   ========================================================================== */

/**
 * Add the correct display in IE 10+.
 */

template {
  display: none;
}

/**
 * Add the correct display in IE 10.
 */

[hidden] {
  display: none;
}
#>>> copy text sakura.css
/* Sakura.css v1.0.0
 * ================
 * Minimal css theme.
 * Project: https://github.com/oxalorg/sakura
 */
/* Body */
html {
  font-size: 62.5%;
  font-family: serif; }

body {
  font-size: 1.8rem;
  line-height: 1.618;
  color: #4a4a4a;
  background-color: #f9f9f9; }

article {
  max-width: 45em;
  margin: auto;
  padding: 13px; }
    
@media (max-width: 684px) {
  body {
    font-size: 1.53rem; } }

@media (max-width: 382px) {
  body {
    font-size: 1.35rem; } }

h1, h2, h3, h4, h5, h6 {
  line-height: 1.1;
  font-family: Verdana, Geneva, sans-serif;
  font-weight: 700;
  overflow-wrap: break-word;
  word-wrap: break-word;
  -ms-word-break: break-all;
  word-break: break-word;
  -ms-hyphens: auto;
  -moz-hyphens: auto;
  -webkit-hyphens: auto;
  hyphens: auto; }

h1 {
  font-size: 2.35em; }

h2 {
  font-size: 2.00em; }

h3 {
  font-size: 1.75em; }

h4 {
  font-size: 1.5em; }

h5 {
  font-size: 1.25em; }

h6 {
  font-size: 1em; }

small, sub, sup {
  font-size: 75%; }

hr {
  border-color: #2c8898; }

a {
  text-decoration: none;
  color: #2c8898; }
  a:hover {
    color: #982c61;
    border-bottom: 2px solid #4a4a4a; }

ul {
  padding-left: 1.4em; }

li {
  margin-bottom: 0.4em; }

blockquote {
  font-style: italic;
  margin-left: 1.5em;
  padding-left: 1em;
  border-left: 3px solid #2c8898; }

img {
  height: auto;
  max-width: 100%; }

/* Pre and Code */
pre {
  background-color: #f1f1f1;
  display: block;
  padding: 1em;
  overflow-x: auto; }

code {
  font-size: 0.9em;
  padding: 0 0.5em;
  background-color: #f1f1f1;
  white-space: pre-wrap; }

pre > code {
  padding: 0;
  background-color: transparent;
  white-space: pre; }

/* Tables */
table {
  text-align: justify;
  width: 100%;
  border-collapse: collapse; }

td, th {
  padding: 0.5em;
  border-bottom: 1px solid #f1f1f1; }

/* Buttons, forms and input */
input, textarea {
  border: 1px solid #4a4a4a; }
  input:focus, textarea:focus {
    border: 1px solid #2c8898; }

textarea {
  width: 100%; }

.button, button, input[type="submit"], input[type="reset"], input[type="button"] {
  display: inline-block;
  padding: 5px 10px;
  text-align: center;
  text-decoration: none;
  white-space: nowrap;
  background-color: #2c8898;
  color: #f9f9f9;
  border-radius: 1px;
  border: 1px solid #2c8898;
  cursor: pointer;
  box-sizing: border-box; }
  .button[disabled], button[disabled], input[type="submit"][disabled], input[type="reset"][disabled], input[type="button"][disabled] {
    cursor: default;
    opacity: .5; }
  .button:focus, .button:hover, button:focus, button:hover, input[type="submit"]:focus, input[type="submit"]:hover, input[type="reset"]:focus, input[type="reset"]:hover, input[type="button"]:focus, input[type="button"]:hover {
    background-color: #982c61;
    border-color: #982c61;
    color: #f9f9f9;
    outline: 0; }

textarea, select, input[type] {
  color: #4a4a4a;
  padding: 6px 10px;
  /* The 6px vertically centers text on FF, ignored by Webkit */
  margin-bottom: 10px;
  background-color: #f1f1f1;
  border: 1px solid #f1f1f1;
  border-radius: 4px;
  box-shadow: none;
  box-sizing: border-box; }
  textarea:focus, select:focus, input[type]:focus {
    border: 1px solid #2c8898;
    outline: 0; }

input[type="checkbox"]:focus {
  outline: 1px dotted #2c8898; }

label, legend, fieldset {
  display: block;
  margin-bottom: .5rem;
  font-weight: 600; }
#>>> copy text theme.css
/* Imports */
@import url("normalize.css");
@import url("sakura.css");
@import url("menu.css");



/*
    Header
*****************/
#banner {
    height: 300px;
    margin: 0;
    padding: 0;
	background-color: #2c8898;
    background-image: linear-gradient(#6a98e5, #2c8898); 
   }
/* Title */
#banner h1{
    color: #fff;
    padding: 0.5em;
}
#>>> copy text _templates/convert_page.htm
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<!-- section meta -->
<base href="$site_url" />
<title>$title</title>
<meta name="date" content="$mdate" />
<meta name="description" content="$description" />
<meta name="keywords" content="$keywords" />
<meta name="author" content="$author" />
<!-- endsection meta -->
</head>
<body>
<header>
<h1>Site Title</h1>
</header>
<article>
<section id="primary">
<!-- section primary -->
<h2>$title</h2>
$body
<!-- endsection primary-->
</section>
<section id="secondary">
<!-- section secondary -->
<!-- endsection secondary-->
</section>
</article>
</body>
</html>
#>>> copy text _templates/create_gallery.htm
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<!-- section meta -->
<base href="$site_url" />
<title>$title</title>
<link href="gallery.css" rel="stylesheet">
<!-- endsection meta -->
</head>
<body>
<header>
<h1>Site Title</h1>
</header>
<article>
<section id="primary">
<!-- section primary -->
<!-- endsection primary-->
</section>
<section id="secondary">
<!-- section secondary -->
<section id="gallery">
<!-- for @files -->
<section class="item">
<a href="#img$count">
<!-- for @thumbfile -->
<img src="$url">
<!-- endfor -->
</a>
</section>
<!-- endfor -->
</section>
<!-- for @files -->
<div class="lightbox" id="img$count">
<div class="box">
<a class="close" href="#">X</a>
 $title
 <div class="content">
 <img src="$url">
 </div>
</div>
</div>
<!-- endfor-->
<!-- endsection secondary-->
</section>
</article>
</body>
</html>
#>>> copy text _templates/create_index.htm
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<!-- section meta -->
<base href="$site_url" />
<title>$title</title>
<!-- endsection meta -->
</head>
<body>
<header>
<h1>Site Title</h1>
</header>
<article>
<section id="primary">
<!-- section primary -->
<!-- endsection primary-->
</section>
<section id="secondary">
<!-- section secondary -->
<h2>$title</h2>

<ul>
<!-- for @files -->
<li><a href="$url">$title</a></li>
<!-- endfor -->
</ul>
<!-- endsection secondary-->
</section>
</article>
</body>
</html>
#>>> copy text _templates/create_news.htm
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<!-- section meta -->
<base href="$site_url" />
<title>$title</title>
<!-- endsection meta -->
</head>
<body>
<header>
<h1>Site Title</h1>
</header>
<article>
<section id="primary">
<!-- section primary -->
<!-- endsection primary-->
</section>
<section id="secondary">
<!-- section secondary -->
<!-- for @top_files -->
<h2>$title</h2>
$body
<p><a href="$url">Written on $date</a></p>
<!-- endfor -->
<h3>Archive</h3>

<p>
<!-- for @folders -->
<a href="$url">$title</a>&nbsp;&nbsp;
<!-- endfor -->
</p>
<!-- endsection secondary-->
</section>
</article>
</body>
</html>
#>>> copy text _templates/create_news_index.htm
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<!-- section meta -->
<base href="$site_url" />
<<title>$title</title>
<!-- endsection meta -->
</head>
<body>
<header>
<h1>Site Title</h1>
</header>
<article>
<section id="primary">
<!-- section primary -->
<!-- endsection primary-->
</section>
<section id="secondary">
<!-- section secondary -->
<h2>$title</h2>

<ul>
<!-- for @folders -->
<li><a href="$url">$title</a></li>
<!-- endfor -->
<!-- for @files -->
<li><a href="$url">$title</a></li>
<!-- endfor -->
</ul>
<!-- endsection secondary-->
</section>
</article>
</body>
</html>
#>>> copy configuration archive/followme.cfg 0
run_before = App::Followme::CreateNews
news_index_file = index.html
news_file = ../essays.html
