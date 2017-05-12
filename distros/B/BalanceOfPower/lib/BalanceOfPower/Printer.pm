package BalanceOfPower::Printer;
$BalanceOfPower::Printer::VERSION = '0.400115';
use Template;
use Cwd 'abs_path';

sub print
{
    my $mode = shift;
    my $world = shift;
    my $template = shift;
    my $vars = shift;

    my $module_file_path = __FILE__;
    my $root_path = abs_path($module_file_path);
    $root_path =~ s/Printer\.pm//;
    $root_path .= "templates";

    my $tt = Template->new({INCLUDE_PATH => "$root_path/$mode",
                            PLUGIN_BASE => 'Template::Plugin::Filter'});

    if(ref $world eq 'BalanceOfPower::World')
    {
        my %nation_codes = reverse %{$world->nation_codes};
        $vars->{'nation_codes'} = \%nation_codes;
    }
    my $output;
    $tt->process("$template.tt", $vars, \$output) || die $tt->error . "\n";
    return $output;
}

1;

