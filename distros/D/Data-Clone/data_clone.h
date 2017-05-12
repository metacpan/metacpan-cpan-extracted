/*
 * data_clone.h - Polymorphic data cloning engine
 *
 * Tihs header file is a part of Data::Clone
 *
 * Copyright (c) 2010, Goro Fuji (gfx).
 *
 * See also http://search.cpan.org/dist/Data-Clone/.
 */

#ifndef PERL_DATA_CLONE_H
#define PERL_DATA_CLONE_H

SV* Data_Clone_sv_clone(pTHX_ SV* const sv);

#define sv_clone(sv) Data_Clone_sv_clone(aTHX_ (sv))

#endif
