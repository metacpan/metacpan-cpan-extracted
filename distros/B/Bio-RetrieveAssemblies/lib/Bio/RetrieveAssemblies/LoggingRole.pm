package Bio::RetrieveAssemblies::LoggingRole;
$Bio::RetrieveAssemblies::LoggingRole::VERSION = '1.1.5';
use Moose::Role;
use Log::Log4perl qw(:easy);

# ABSTRACT: Role for logging


has 'logger'                  => ( is => 'rw', lazy => 1, builder => '_build_logger');
has 'verbose'                 => ( is => 'rw', isa => 'Bool',      default  => 0 );

sub _build_logger
{
    my ($self) = @_;
    Log::Log4perl->easy_init(level => $ERROR);
    my $logger = get_logger();
    return $logger;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::RetrieveAssemblies::LoggingRole - Role for logging

=head1 VERSION

version 1.1.5

=head1 SYNOPSIS

Role for logging

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
