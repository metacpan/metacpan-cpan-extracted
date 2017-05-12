package Bundle::Bonsai;

$VERSION = '0.01';

1;

__END__

=head1 NAME

Bundle::Tinderbox - A bundle of the modules required for Bonsai.

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::Bonsai'>

=head1 CONTENTS

DBI

Data::Dumper

DBD::mysql

Bundle::Libnet

Mail::Tools

Time::Date

=head1 DESCRIPTION

This bundle installs the prerequisites for Bonsai.

=over 4

=item DBI
This module is used to connect to the database that Bonsai uses 
to store its information.

=item Data::Dumper
The Data::Dumper module provides data structure persistence for Perl
(similar to Java's serialization).  It comes with later sub-releases of
Perl 5.004, but a re-installation just to be sure it's available won't
hurt anything. Data::Dumper is used by the MySQL related Perl modules.

=item DBD::mysql
This module is used to connect to the mysql database that Bonsai uses 
to store its information.

=item Bundle::Libnet
Makes the magic work

=item Mail::Tools
For sending mail (what else?)

=item Time::Date
Handles the time for Bonsai

=head1 AUTHOR

Zach Lipton, <zach@zachlipton.com>

