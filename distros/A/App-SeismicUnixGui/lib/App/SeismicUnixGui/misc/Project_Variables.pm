package App::SeismicUnixGui::misc::Project_Variables;

# DATE      format is DAY MONTH YEAR
# ENVIRONMENT VARIABLES FOR THIS PROJECT
# Notes:
# 1. Default DATE format is DAY MONTH YEAR
# 2. only change what lies between single
# inverted commas
# 3. the directory hierarchy is
# $PROJECT_HOME/$date/$line
# Warning: Do not modify $HOME
use Moose;
our $VERSION = '0.0.1';

my $home_directory;
my $HOME;

BEGIN {
    use Shell qw(echo);

    my $home_directory = ` echo \$HOME`;
    chomp $home_directory;
    $HOME = $home_directory;
}


# default values are required

my $PROJECT_HOME = $HOME . '/FalseRiver';
my $site         = 'core_1';

#
my $monitoring_well  = '';
my $preparation_well = '041914';
my $stage            = 'H';
my $process          = '1';
#
sub date {

    my $date = $site;
    return ($date);
}

sub HOME {
    return ($HOME);
}

sub PROJECT_HOME {
    return ($PROJECT_HOME);
}

sub line {
    my $line = $monitoring_well;
    return ($line);
}

sub component {
    my $component = $preparation_well;
    return ($component);
}

sub stage {
    return ($stage);
}

sub process {
    return ($process);
}

1;
