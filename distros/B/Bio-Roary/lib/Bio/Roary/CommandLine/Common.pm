package Bio::Roary::CommandLine::Common;
# ABSTRACT: Common command line settings
$Bio::Roary::CommandLine::Common::VERSION = '3.11.3';

use Moose;
use FindBin;
use Log::Log4perl qw(:easy);

has 'logger'                  => ( is => 'ro', lazy => 1, builder => '_build_logger');
has 'version'                 => ( is => 'rw', isa => 'Bool', default => 0 );

sub _build_logger
{
    my ($self) = @_;
    Log::Log4perl->easy_init($ERROR);
    my $logger = get_logger();
    return $logger;
}


sub run {
	my ($self) = @_;
}

sub usage_text {
    my ($self) = @_;
	return "Usage text";
}

sub _version {
    my ($self) = @_;
    return "x.y.z\n";
}


# add our included binaries to the END of the PATH
before 'run' => sub {
	my ($self) = @_;
	my $OPSYS = $^O;
	my $BINDIR = "$FindBin::RealBin/../binaries/$OPSYS";

    for my $dir ($BINDIR, $FindBin::RealBin) {
      if (-d $dir) {
        $ENV{PATH} .= ":$dir";
       }
  }
};

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::Roary::CommandLine::Common - Common command line settings

=head1 VERSION

version 3.11.3

=head1 SYNOPSIS

Common command line settings

   extends 'Bio::Roary::CommandLine::Common';

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
