use inc::Module::Install;

name 'CatalystX-Example-YUIUploader';
all_from 'lib/CatalystX/Example/YUIUploader.pm';

requires 'Catalyst::Runtime' => '5.7012';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'YAML'; # This should reflect the config file format you've chosen
                 # See Catalyst::Plugin::ConfigLoader for supported formats
requires 'Data::UUID';
requires 'MIME::Types';
requires 'Catalyst::View::TT';
requires 'Catalyst::View::JSON';
catalyst;

sub MY::install {
    return <<_END_
install:
\t\@echo
\t\@echo "*********************************************************"
\t\@echo "* Installing this package is not recommended, just      *"
\t\@echo "* download, extract, and then run:                      *"
\t\@echo "*                                                       *"
\t\@echo "* ./script/catalystx_example_yuiuploader_server.pl      *"
\t\@echo "*                                                       *"
\t\@echo "*********************************************************"
\t\@echo
_END_
}

auto_install;
WriteAll;
