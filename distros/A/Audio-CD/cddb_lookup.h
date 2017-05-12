typedef int (*cddb_inexact_selection_func_t)(void);

void cddb_lookup(int cd_desc, struct disc_data *data);
void cddb_verbose(void *h, int flag);
void cddb_inexact_selection_set(cddb_inexact_selection_func_t func);
