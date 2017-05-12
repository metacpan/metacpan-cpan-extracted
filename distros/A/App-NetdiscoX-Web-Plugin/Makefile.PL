use inc::Module::Install;
  
name     'App-NetdiscoX-Web-Plugin-JackReport';
license  'bsd';
all_from 'lib/App/NetdiscoX/Web/Plugin/JackReport.pm';
  
install_share 'share';
 
WriteAll;
