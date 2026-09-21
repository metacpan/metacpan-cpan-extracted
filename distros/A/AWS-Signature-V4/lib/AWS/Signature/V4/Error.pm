package AWS::Signature::V4::Error;
use v5.24;
use Carp ();
use Exporter qw< import >;
use Ouch ();

our @EXPORT_OK = qw< fail shown >;

# Errors are reported at the caller's line, as croak would do: the frames of
# this distribution are skipped when Ouch looks for the culprit.
$Carp::Internal{$_}++ for qw<
   AWS::Signature::V4 AWS::Signature::V4::Checksum
   AWS::Signature::V4::Chunker AWS::Signature::V4::Credentials
   AWS::Signature::V4::Error AWS::Signature::V4::X509
>;

# 400 for what the caller provided, 500 for problems inside the module;
# everything is passed down to ouch(), the optional third argument included.
# No "goto": it would drop the "local" before ouch() gets to build the trace.
sub fail {
   local $Carp::MaxArgNums = -1;    # the trace must not hold secrets
   Ouch::ouch(@_);
}

# caller input, made safe to put in a message: anything that is not printable
# ASCII is escaped, so that it cannot forge lines in a log
sub shown {
   my ($value) = @_;
   return 'undef' unless defined $value;
   return $value =~ s{([^\x20-\x7E])}{sprintf '\\x{%X}', ord $1}ger;
}

1;
