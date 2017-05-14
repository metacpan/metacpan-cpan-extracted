##CelegansInteractome version 1.2
Author: Damien O'Halloran, The George Washington University, 2016

![CelegansInteractome_Perl LOGO](https://cloud.githubusercontent.com/assets/8477977/20890549/46418d36-bad5-11e6-88c2-015efe941d5c.png)

##Installation
1. Download and extract the CelegansInteractome.zip file  
`tar -xzvf CelegansInteractome.zip`  
2. The extracted dir will be called CelegansInteractome  
  `cd CelegansInteractome`   
  `perl Makefile.PL`  
  `make`  
  `make test`  
  `make install`  

##Usage 
Run as follows:  
  `use CelegansInteractome;`   
  `use GraphViz;`  
  `use LWP::Simple;`  
  
 
 `my $tmp = CelegansInteractome->new();`   
 `$tmp->load_interactome(`   
    `wormbase_version    => $wormbase_version || "WS239",`   
    `in_file             => $in_file,`   
    `out_file            => $out_file,`   
    `cleanup             => "0"`   
 `);`   
 
 `$tmp->graph_interactome();`     
 


## Contributing
All contributions are welcome.

## Support
If you have any problem or suggestion please open an issue [here](https://github.com/dohalloran/CelegansInteractome/issues).

## License 
GNU GENERAL PUBLIC LICENSE





