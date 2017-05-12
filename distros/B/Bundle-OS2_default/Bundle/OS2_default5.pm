package Bundle::OS2_default5;

$VERSION = '1.01';

1;

=head1 NAME

Bundle::OS2_default5 - DateBase Modules for OS/2 binary distribution

=head1 SYNOPSIS

  perl -MCPAN -e "install Bundle::OS2_default5"

  perl_ -MCPAN -e "install Bundle::OS2_default5"

=head1 CONTENTS

DBI		- Core DBI support

# Bundle::DBD::CSV	- Simple DBD interface (references DBD::CSV, which is misindexed)

Text::CSV_XS 0.14	- from Bundle::DBD::CSV

SQL::Statement 0.1006	- from Bundle::DBD::CSV

# DBD::CSV		- from Bundle::DBD::CSV, misindexed due to backlevel 0.2002 to 0.1030


DBD::File	- required for DBD::RAM, will fetch DBD::CSV too

DBD::RAM	- Simple DBD interface

DBD::SQLite	- Another server-less implementation

=cut

