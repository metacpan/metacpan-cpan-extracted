use inc::Module::Install;
  
name     'App-NetdiscoX-Web-Plugin-GraphLink';
license  'bsd';
all_from 'lib/App/NetdiscoX/Web/Plugin/GraphLink.pm';
  
install_share 'share';
 
WriteAll;
