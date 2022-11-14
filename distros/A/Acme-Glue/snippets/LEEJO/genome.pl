use Boulder::Stream; 
$stream = new Boulder::Stream; 
while ($record=$stream->read_record('NAME','SEQUENCE')) {
   $name = $record->get('NAME'); 
   $sequence = $record->get('SEQUENCE'); 
   
   # ...continue processing...
   
   $record->add(QUALITY_CHECK=>"OK|); 
   $stream->write_record($record); 
} 
