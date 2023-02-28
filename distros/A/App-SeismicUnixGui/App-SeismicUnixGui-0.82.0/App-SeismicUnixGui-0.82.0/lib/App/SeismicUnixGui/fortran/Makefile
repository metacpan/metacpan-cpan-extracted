# ============================================================================
# Name        : Makefile
# Author      : Juan Lorenzo 
# Version     : 0.1
# Copyright   : Please copy
# Description : Makefile for immodpg
# ============================================================================

.PHONY: all clean

# Change the next line if you are using a different Fortran compiler
FORTRAN_COMPILER = gfortran
F77 = -iffixed-form
F98 = -ffree-form -ffree-line-length-none
FORTRAN98_FLAGS    = -O2 -g $(F98)
FORTRAN_77_FLAGS    = -O2 -g $(F98)

PGPLOT=$(PGPLOT_DIR)

# where is your working directory
SeismicUnixGui_FORTRAN = $(PWD)

# location of code
SeismicUnixGui_FORTRAN_SRC = $(SeismicUnixGui_FORTRAN)/src

# folder for binaries
SeismicUnixGui_FORTRAN_BIN = $(SeismicUnixGui_FORTRAN)/bin

BIN_OUT          = $(SeismicUnixGui_FORTRAN_BIN)

# folder for object files
SeismicUnixGui_FORTRAN_OBJ = $(SeismicUnixGui_FORTRAN)/obj

# Rules

# objects = Project_config
# all: $(objects)
# $(objects): %: %.f

# compile F98 source code
Project_config.o:	$(SeismicUnixGui_FORTRAN_SRC)/Project_config.f
	$(FORTRAN_COMPILER) $(FORTRAN98_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/Project_config.f \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/Project_config.o

main.o:	$(SeismicUnixGui_FORTRAN_SRC)/main.f
	$(FORTRAN_COMPILER) $(FORTRAN98_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/main.f \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/main.o

main: main.o read_1col.o write_1col.o
	$(FORTRAN_COMPILER) $(FORTRAN98_FLAGS) \
	$(SeismicUnixGui_FORTRAN_OBJ)/main.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/read_1col.o \
	-o $(SeismicUnixGui_FORTRAN_BIN)/main
	
readVbot_file.o: $(SeismicUnixGui_FORTRAN_SRC)/readVbot_file.f
	$(FORTRAN_COMPILER) $(FORTRAN98_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/readVbot_file.f \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/readVbot_file.o
	
readVbot_upper_file.o: $(SeismicUnixGui_FORTRAN_SRC)/readVbot_upper_file.f
	$(FORTRAN_COMPILER) $(FORTRAN98_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/readVbot_upper_file.f \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/readVbot_upper_file.o
	
readVtop_file.o: $(SeismicUnixGui_FORTRAN_SRC)/readVtop_file.f
	$(FORTRAN_COMPILER) $(FORTRAN98_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/readVtop_file.f \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/readVtop_file.o
	
readVtop_lower_file.o: $(SeismicUnixGui_FORTRAN_SRC)/readVtop_lower_file.f
	$(FORTRAN_COMPILER) $(FORTRAN98_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/readVtop_lower_file.f \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/readVtop_lower_file.o
			
readVincrement_file.o: $(SeismicUnixGui_FORTRAN_SRC)/readVincrement_file.f
	$(FORTRAN_COMPILER) $(FORTRAN98_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/readVincrement_file.f \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/readVincrement_file.o
	
readVbotNtop_factor_file.o: $(SeismicUnixGui_FORTRAN_SRC)/readVbotNtop_factor_file.f
	$(FORTRAN_COMPILER) $(FORTRAN98_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/readVbotNtop_factor_file.f \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/readVbotNtop_factor_file.o
	
read_bin_data.o: $(SeismicUnixGui_FORTRAN_SRC)/read_bin_data.f
	$(FORTRAN_COMPILER) $(FORTRAN98_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/read_bin_data.f \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/read_bin_data.o
	
read_immodpg_config.o: $(SeismicUnixGui_FORTRAN_SRC)/read_immodpg_config.f
	$(FORTRAN_COMPILER) $(FORTRAN98_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/read_immodpg_config.f \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/read_immodpg_config.o
	
read_clip_file.o: $(SeismicUnixGui_FORTRAN_SRC)/read_clip_file.f
	$(FORTRAN_COMPILER) $(FORTRAN98_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/read_clip_file.f \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/read_clip_file.o
	
read_layer_file.o: $(SeismicUnixGui_FORTRAN_SRC)/read_layer_file.f
	$(FORTRAN_COMPILER) $(FORTRAN98_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/read_layer_file.f \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/read_layer_file.o
	
read_thickness_increment_m_file.o: $(SeismicUnixGui_FORTRAN_SRC)/read_thickness_increment_m_file.f
	$(FORTRAN_COMPILER) $(FORTRAN98_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/read_thickness_increment_m_file.f \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/read_thickness_increment_m_file.o
	
read_thickness_m_file.o: $(SeismicUnixGui_FORTRAN_SRC)/read_thickness_m_file.f
	$(FORTRAN_COMPILER) $(FORTRAN98_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/read_thickness_m_file.f \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/read_thickness_m_file.o
	
read_option_file.o: $(SeismicUnixGui_FORTRAN_SRC)/read_option_file.f
	$(FORTRAN_COMPILER) $(FORTRAN98_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/read_option_file.f \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/read_option_file.o
	
read_parmmod_file.o: $(SeismicUnixGui_FORTRAN_SRC)/read_parmmod_file.f
	$(FORTRAN_COMPILER) $(FORTRAN98_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/read_parmmod_file.f \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/read_parmmod_file.o		
	
read_yes_no_file.o: $(SeismicUnixGui_FORTRAN_SRC)/read_yes_no_file.f
	$(FORTRAN_COMPILER) $(FORTRAN98_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/read_yes_no_file.f \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/read_yes_no_file.o
	
#stdsleep.o: $(SeismicUnixGui_FORTRAN_SRC)/stdsleep.f
#	$(FORTRAN_COMPILER) $(FORTRAN98_FLAGS) \
#	-c $(SeismicUnixGui_FORTRAN_SRC)/stdsleep.f \
#	-o $(SeismicUnixGui_FORTRAN_OBJ)/stdsleep.o

write_model_file_text.o: $(SeismicUnixGui_FORTRAN_SRC)/write_model_file_text.f
	$(FORTRAN_COMPILER) $(FORTRAN98_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/write_model_file_text.f \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/write_model_file_text.o

write_yes_no_file.o: $(SeismicUnixGui_FORTRAN_SRC)/write_yes_no_file.f
	$(FORTRAN_COMPILER) $(FORTRAN98_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/write_yes_no_file.f \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/write_yes_no_file.o

# compile F77 fortran source code by Emilio Vera	
messa.o:$(SeismicUnixGui_FORTRAN_SRC)/messa.for
	$(FORTRAN_COMPILER) $(FORTRAN77_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/messa.for \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/messa.o
		
immodpg.o:$(SeismicUnixGui_FORTRAN_SRC)/immodpg.for
	$(FORTRAN_COMPILER) $(FORTRAN77_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/immodpg.for \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/immodpg.o
	
readpar.o: $(SeismicUnixGui_FORTRAN_SRC)/readpar.for
	$(FORTRAN_COMPILER) $(FORTRAN77_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/readpar.for \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/readpar.o
	
rdata.o: $(SeismicUnixGui_FORTRAN_SRC)/rdata.for
	$(FORTRAN_COMPILER) $(FORTRAN77_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/rdata.for \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/rdata.o

read_dataxy.o: $(SeismicUnixGui_FORTRAN_SRC)/read_dataxy.for
	$(FORTRAN_COMPILER) $(FORTRAN77_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/read_dataxy.for \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/read_dataxy.o
	
readmmod.o: $(SeismicUnixGui_FORTRAN_SRC)/readmmod.for
	$(FORTRAN_COMPILER) $(FORTRAN77_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/readmmod.for \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/readmmod.o
denfvp.o:  $(SeismicUnixGui_FORTRAN_SRC)/denfvp.for
	$(FORTRAN_COMPILER) $(FORTRAN77_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/denfvp.for \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/denfvp.o
	
thi.o: $(SeismicUnixGui_FORTRAN_SRC)/thi.for
	$(FORTRAN_COMPILER) $(FORTRAN77_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/thi.for \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/thi.o
	
wrimod2.o: $(SeismicUnixGui_FORTRAN_SRC)/wrimod2.for
	$(FORTRAN_COMPILER) $(FORTRAN77_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/wrimod2.for \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/wrimod2.o
	
txpr.o: $(SeismicUnixGui_FORTRAN_SRC)/txpr.for
	$(FORTRAN_COMPILER) $(FORTRAN77_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/txpr.for \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/txpr.o
txgrd.o: $(SeismicUnixGui_FORTRAN_SRC)/txgrd.for
	$(FORTRAN_COMPILER) $(FORTRAN77_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/txgrd.for \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/txgrd.o
moveNzoom.o: $(SeismicUnixGui_FORTRAN_SRC)/moveNzoom.for
	$(FORTRAN_COMPILER) $(FORTRAN77_FLAGS) \
	-c $(SeismicUnixGui_FORTRAN_SRC)/moveNzoom.for \
	-o $(SeismicUnixGui_FORTRAN_OBJ)/moveNzoom.o

# link and build executable with both F77 and F98 files

#stdsleep: stdsleep.o
#	$(FORTRAN_COMPILER) \
#	$(SeismicUnixGui_FORTRAN_OBJ)/stdsleep.o \
#	-o$(SeismicUnixGui_FORTRAN_BIN)/stdsleep
	
immodpg1.1: immodpg.o readpar.o rdata.o read_dataxy.o readmmod.o \
denfvp.o thi.o wrimod2.o txpr.o txgrd.o moveNzoom.o \
readVbot_file.o readVtop_lower_file.o readVbot_upper_file.o  readVtop_file.o  \
readVincrement_file.o readVbotNtop_factor_file.o read_bin_data.o \
read_immodpg_config.o \
read_clip_file.o read_layer_file.o read_thickness_m_file.o  read_thickness_increment_m_file.o  \
read_option_file.o read_parmmod_file.o \
read_yes_no_file.o \
write_model_file_text.o write_yes_no_file.o \
messa.o Project_config.o
	$(FORTRAN_COMPILER) \
	$(SeismicUnixGui_FORTRAN_OBJ)/thi.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/wrimod2.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/txpr.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/txgrd.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/denfvp.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/moveNzoom.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/immodpg.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/messa.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/readpar.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/rdata.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/read_dataxy.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/readmmod.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/readVbot_file.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/readVbot_upper_file.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/readVtop_file.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/readVtop_lower_file.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/readVincrement_file.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/readVbotNtop_factor_file.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/read_bin_data.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/read_immodpg_config.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/read_clip_file.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/read_layer_file.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/read_thickness_increment_m_file.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/read_thickness_m_file.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/read_option_file.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/read_parmmod_file.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/read_yes_no_file.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/write_model_file_text.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/write_yes_no_file.o \
	$(SeismicUnixGui_FORTRAN_OBJ)/Project_config.o \
	-L$(PGPLOT) -lpgplot  -L/usr/lib64 -lX11 -o$(SeismicUnixGui_FORTRAN_BIN)/immodpg1.1
#	$(SeismicUnixGui_FORTRAN_OBJ)/stdsleep.o \	
clean:
	echo $(SeismicUnixGui_FORTRAN_BIN); \
	echo $(SeismicUnixGui_FORTRAN_OBJ)
	rm -f $(SeismicUnixGui_FORTRAN_BIN)/immodpg1.1
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/thi.o
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/wrimod2.o
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/txpr.o
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/txgrd.o
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/denfvp.o
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/moveNzoom.o
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/immodpg.o
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/messa.o
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/readpar.o
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/rdata.o
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/read_dataxy.o	
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/readmmod.o
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/readVbot_file.o
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/readVbot_upper_file.o
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/readVtop_file.o
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/readVtop_lower_file.o
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/readVincrement_file.o
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/readVbotNtop_factor_file.o
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/read_bin_data.o
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/read_immodpg_config.o
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/read_clip_file.o
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/read_layer_file.o
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/read_thickness_increment_m_file.o
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/read_thickness_m_file.o
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/read_option_file.o
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/read_parmmod_file.o
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/read_yes_no_file.o
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/write_model_file_text.o
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/write_yes_no_file.o
	rm -f $(SeismicUnixGui_FORTRAN_OBJ)/Project_config.o
	