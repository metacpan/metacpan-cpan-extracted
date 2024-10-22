# source ~/emsdk/emsdk_env.sh
CC:=emcc
SRCDIR?=src
MINIAUDIODIR?=deps/miniaudio
DRFLACDIR?=deps/dr_libs
OUTDIR?=bin
TARGET:=$(OUTDIR)/_mhfscl.js
EXPORTED_RUNTIME_METHODS := $(shell perl exported_runtime_methods.pl)
STACK_SIZE_NAME := $(shell perl stack_size_name.pl)

CFLAGS:=-Wall -Wextra -I$(DRFLACDIR) -I$(MINIAUDIODIR) -DMA_NO_DEVICE_IO -DMA_NO_THREADING -DMA_NO_ENCODING -DDR_FLAC_BUFFER_SIZE=65536 -DDR_FLAC_NO_OGG $(EXPORTED_RUNTIME_METHODS) -s'EXPORTED_FUNCTIONS=["_malloc", "_realloc", "_free"]' -sEXPORT_ES6=1 -s$(STACK_SIZE_NAME)=128KB -sALLOW_MEMORY_GROWTH=1 -sMODULARIZE=1 -sALLOW_TABLE_GROWTH=1

# a non zero value turns on Werrror
MHFS_CL_DEC_Werror?=0
WARNINGS_AS_ERRORS := $(shell test $(MHFS_CL_DEC_Werror) -ne 0; echo $$? )
ifeq ($(WARNINGS_AS_ERRORS), 0)
	CFLAGS += -Werror
endif

# Debug levels, 0-2 0 being not debugging, 2 being full debugging
MHFS_CL_DEC_DBG_LVL?=0
DEBUG_LEVEL_GE_ONE := $(shell test $(MHFS_CL_DEC_DBG_LVL) -ge 1; echo $$? )
DEBUG_LEVEL_GE_TWO := $(shell test $(MHFS_CL_DEC_DBG_LVL) -ge 2; echo $$? )
ifeq ($(DEBUG_LEVEL_GE_ONE), 0)
	CFLAGS += -O0 -g4 --source-map-base ./ -s SAFE_HEAP=1 -DMHFSCLTR_PRINT_ON=1 -DMHFSCLDEC_PRINT_ON=1
	ifeq ($(DEBUG_LEVEL_GE_TWO), 0)
		CFLAGS += -DBLOCKVF_PRINT_ON=1 -sASSERTIONS=2
	else
		CFLAGS += -sASSERTIONS=1
	endif
else
	CFLAGS += -O3
endif

$(TARGET): $(SRCDIR)/mhfs_cl.c $(DRFLACDIR)/dr_flac.h $(MINIAUDIODIR)/miniaudio.h $(SRCDIR)/blockvf.h $(SRCDIR)/mhfs_cl_track.h $(SRCDIR)/mhfs_cl_decoder.h $(SRCDIR)/exposetype.h $(SRCDIR)/mhfs_cl_misc.h $(SRCDIR)/mhfs_cl.h
	mkdir -p $(OUTDIR)
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -rf $(OUTDIR)/*

.PHONY: clean
