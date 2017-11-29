#converts a mysql database to tab seperated readable by LBD
#command is of the form:
#`mysql <DB_NAME> -e "SELECT * FROM N_11 INTO OUTFILE '<OUTPUT_FILE>' FIELDS TERMINATED BY '\t' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n';"`
#
# the following line is an example using a database with cui co-occurrence 
# counts from 1980 to 1984 with a window size of 1. The mysql database is 
# called 1980_1984_window1, and the output matrix file is called 
# 1980_1984_window1_data.txt
`mysql 1980_1984_window1 -e "SELECT * FROM N_11 INTO OUTFILE '1980_1984_window1_data.txt' FIELDS TERMINATED BY '\t' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n';"`;
