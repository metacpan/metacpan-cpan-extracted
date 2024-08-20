#ifndef __CONSTRAINTS_H__
#define __CONSTRAINTS_H__

struct Constraint;

typedef bool ConstraintFunc(pTHX_ struct Constraint *c, SV *value);

struct Constraint
{
  ConstraintFunc *func;
  int flags; /* avoids needing an entire SV just for a few numeric flag bits */
  size_t n;
  SV *args[0];
};

#define stringify_constraint(c)       DataChecks_stringify_constraint(aTHX_ c)
#define stringify_constraint_sv(csv)  DataChecks_stringify_constraint(aTHX_ (struct Constraint *)SvPVX(csv))
SV *DataChecks_stringify_constraint(pTHX_ struct Constraint *c);

#define extract_constraint(sv)  DataChecks_extract_constraint(aTHX_ sv)
SV *DataChecks_extract_constraint(pTHX_ SV *sv);

void boot_Data_Checks__constraints(pTHX);

#endif
