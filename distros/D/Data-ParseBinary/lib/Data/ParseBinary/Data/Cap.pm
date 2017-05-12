package Data::ParseBinary::Data::Cap;
use strict;
use warnings;
use Data::ParseBinary;
use Data::ParseBinary qw{OptionalGreedyRange};
#"""
#tcpdump capture file
#"""


my $packet = Struct("packet",
    Data::ParseBinary::lib::DataCap::MicrosecAdapter->create(
        Sequence("time", 
            ULInt32("time"),
            ULInt32("usec"),
        )
    ),
    ULInt32("length"),
    Padding(4),
    Field("data", sub { $_->ctx->{length} }),
);

our $data_cap_parser = Struct("cap_file",
    Padding(24),
    OptionalGreedyRange($packet),
);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($data_cap_parser);

package Data::ParseBinary::lib::DataCap::MicrosecAdapter;
our @ISA;
BEGIN { @ISA = qw{Data::ParseBinary::Adapter}; }

sub _decode {
    my ($self, $value) = @_;
    return sprintf("%d.%06d", @$value)
}

sub _encode {
    my ($self, $tvalue) = @_;
    if ( index($tvalue, ".") >= 0 ) {
        my ($sec, $usec) = $tvalue =~ /^(\d+)\.(\d*)$/;
        if (length($usec) > 6) {
            $usec = substr($usec, 0, 6);
        } else {
            $usec .= "0" x (6 - length($usec));
        }
        return [$sec, $usec];
    } else {
        return [$tvalue, 0];
    }
}
    #def _decode(self, obj, context):
    #    return datetime.fromtimestamp(obj[0] + (obj[1] / 1000000.0))
    #def _encode(self, obj, context):
    #    offset = time.mktime(*obj.timetuple())
    #    sec = int(offset)
    #    usec = (offset - sec) * 1000000
    #    return (sec, usec)


1;

__END__

=head1 NAME

Data::ParseBinary::Data::Cap - Parsing "tcpdump capture file"

=head1 SYNOPSIS

    use Data::ParseBinary::Data::Cap qw{$data_cap_parser};
    my $data = $data_cap_parser->parse(CreateStreamReader(File => $fh));

Parsing "tcpdump capture file", whatever it is. Please note that this parser
have a lot of white space. (paddings) So when I rebuild the file, the padded
area is zeroed, and the re-created file does not match the original file.

I don't know if the recreated file is valid. 

This is a part of the Data::ParseBinary package, and is just one ready-made parser.
please go to the main page for additional usage info.

=cut
