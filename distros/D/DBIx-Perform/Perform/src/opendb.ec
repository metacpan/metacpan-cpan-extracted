$include sqlca;
#define MAX 256

int  opendb(char  *dbname) {
  $char dbnamecp[MAX];

  strncpy(dbnamecp, dbname, MAX);
  $database optifacts;

  return sqlca.sqlcode;
}
