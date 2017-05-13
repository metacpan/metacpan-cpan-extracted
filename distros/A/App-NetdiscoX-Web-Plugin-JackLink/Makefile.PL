use inc::Module::Install;
  
name     'App-NetdiscoX-Web-Plugin-JackLink';
license  'bsd';
all_from 'lib/App/NetdiscoX/Web/Plugin/JackLink.pm';
  
install_share 'share';
 
WriteAll;
