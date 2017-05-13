use inc::Module::Install;
  
name     'App-NetdiscoX-Web-Plugin-GraphLinkSwitch';
license  'bsd';
all_from 'lib/App/NetdiscoX/Web/Plugin/GraphLinkSwitch.pm';
  
install_share 'share';
 
WriteAll;
