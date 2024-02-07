	SUBROUTINE READMMOD(VT,VB,DZ,VST,VSB,RHOT,RHOB,NL)
	DIMENSION VT(*),VB(*),DZ(*),VST(*),VSB(*),RHOT(*),RHOB(*)
	CHARACTER*40 FOUT
	CHARACTER*8 STAT
!      JML 20, 3 lines foll.
	real*4    result(20)
	character*40  model_file_in, base_file
	character*255 set_DIR, get_DIR, config_file_in
	character*255 inbound_config, inbound_model
	real      previous_model,new_model
	LOGICAL EX
	IOUT=25
	IIN=26
	IOP=3
	model_file_in='immodpg.out'
	config_file_in = 'immodpg.config'
	idef=0
	ID=0


c READS A VELOCITY DEPTH MODEL OF NL LAYERS. VT(I),VB(I),DZ(I) ARE TOP
c AND BOTTOM P-WAVE VELOCITIES AND THICKNESS OF LAYER I AND VST(I),
c VSB(I),RHOT(I),RHOB(I) ARE ITS S-WAVE VELOCITY AND DENSITY AT
c TOP AND BOTTOM RESPECTIVELY.
c

! read all the configuration parameters for the Current Project
! to define the different needed directories
      set_DIR = "IMMODPG"
      call Project_config(set_DIR,get_DIR)
      inbound_config = trim(get_DIR)//"/"//config_file_in
      inbound_model = trim(get_DIR)//"/"//model_file_in
!      print*, '1. readmmod.for,inbound=',trim(inbound),'--'

! read all the configuration parameters for mmodpg JML 2020
!      next 7 lines
      call read_immodpg_config(base_file,result,inbound_config)
      previous_model = result(14)
      new_model      = result(15)
!      print*, '1. readmmod.for,previous_model=',previous_model,'--'
!      print*, '1. readmmod.for,new_model=',new_model,'--'
      if (previous_model == 0.0 .and. new_model == 1.0) then
       ID=0
       write(*,*) '1- CREATE A GRADIENT VEL. MODEL (Binary FORMAT)'
       CALL READ_PAR_I4('0- READ/MODIFY OLD MODEL ',ID)

      else if (previous_model == 1.0 .and. new_model == 0.0) then
       ID =0
!       print *, 'L49 readmmod.for, correct answer'
      else
       print *, 'readmmod.for, unexpected model answer'
      end if

	IF(ID.EQ.0) go to 110
c
	ID=2
	write(*,*) 'DEFINE THE MODEL USING :'
	write(*,*)
	CALL READ_PAR_I4('0-DEPTH,1-TWTT(P-WAVE),2-LAYER THICKNESS',ID)
c
        write(*,*) 'ENTER P- WAVE VELOCITIES(KM/SEC) AND ACCORDING'
        write(*,*) 'TO YOUR PREVIOUS CHOICE ENTER EITHER DEPTH(KM)'
        write(*,*) 'OR 2-WAY TRAVEL TIME(SEC) TO THE BOTTOM OF'
        write(*,*) 'THE LAYER OR THICKNESS(KM).'
        write(*,*) '*** GIVE VPTOP= NEGATIVE NUMBER TO END .***'
	write(*,*)
	write(*,*) 'INITIALLY THE SHEAR VELOCITIES WILL BE SET'
	write(*,*) 'ACCORDING TO THE SPECIFIED VS/VP RATIO, AND THE'
	write(*,*) 'DENSITIES BY:'
	write(*,*)
	write(*,*) '** IOP=1 **'
	write(*,*) 'RHO=1.74*VP**0.25 ,GARDNER ET AL.,GEOPHYSICS 39,'
	write(*,*) '                   P 770-780,1974'
	write(*,*) '** IOP=2 **'
	write(*,*) 'RHO=1.85+0.165*VP ,CHRISTENSEN AND SHAW,GEOPHYS.J.R'
	write(*,*) '                   ASTR.SOC.,P 271-284,1970; BASALT'
	write(*,*) '                   SAMPLES AT 1 KBAR.'
	write(*,*) '** IOP=3 **'
	write(*,*) ' NAFE AND DRAKE, THE SEA VOL.4,PART 1,WILEY-INTER-'
	write(*,*) 'SCIENCES,NEW YORK,1970.'
	write(*,*)
	write(*,*) 'FOR THE FIRST LAYER VS=0.0, RHO=1.0'
	write(*,*)
	VSVPR=0.0
	CALL READ_PAR_R4('VS/VP RATIO TO DEFAULT VS?',VSVPR)
	CALL READ_PAR_I4(' IOP TO DEFINE DENSITIES ?',IOP)
c
	I=1
	DE1=1.5
	AU1=0.
 10	write(*,*) 'LAYER ',I
	write(*,*)
	VT(I)=DE1
	CALL READ_PAR_R4('VPTOP (KM/SEC) ?',VT(I))
	IF(VT(I).LT.0) GO TO 100
	CALL READ_PAR_R4('VPBOTTOM (KM/SEC) ?',VB(I))
	CALL READ_PAR_R4('DEPTH OR TWTT OR THICKNESS (KM OR SEC)?',AU2)
	VST(I)=VSVPR*VT(I)
	VSB(I)=VSVPR*VB(I)
	CALL DENFVP(VT(I),RHOT(I),IOP)
	CALL DENFVP(VB(I),RHOB(I),IOP)
	IF(I.EQ.1) THEN
	VST(I)=0.0
	VSB(I)=0.0
	RHOT(I)=1.0
	RHOB(I)=1.0
	ENDIF
	CALL READ_PAR_R4(
     +  'VSTOP (KM/SEC)? (ENTER 0.0 TO DEFINE A FLUID)',VST(I))
	CALL READ_PAR_R4(
     +  'VSBOTTOM (KM/SEC)? (ENTER 0.0 TO DEFINE A FLUID)',VSB(I))
	CALL READ_PAR_R4('TOP DENSITY (G/CC) ?',RHOT(I))
	CALL READ_PAR_R4('BOTTOM DENSITY (G/CC) ?',RHOB(I))
c
	IF(ID.EQ.0) THEN
	DZ(I)=AU2-AU1
	AU1=AU2
	ELSE
		IF(ID.EQ.1) THEN
		AU3=AU2-AU1 ! LAYER I TWO WAY TRAVEL TIME
		AU1=AU2
		CALL THI(AU3,VT(I),VB(I),DZ(I))
		ELSE
		DZ(I)=AU2
		ENDIF
	ENDIF
	I=I+1
	DE1=VB(I-1)
	GO TO 10
100	NL=I-1
   	VB(I)=0.0
	DZ(I)=0.0
	VST(I)=0.0
	VSB(I)=0.0
	RHOT(I)=0.0
	RHOB(I)=0.0
c
c *** WRITE MODEL IN FILE ***
c
97      ID=1
  	CALL READ_PAR_I4('1- WRITE MODEL IN FILE, 0- NO',ID)
	IF(ID.EQ.0) GO TO 135
	STAT='NEW'
103	write(*,*)'OUTPUT FILE NAME ?? '
	READ(*,'(A)') FOUT
	INQUIRE(FILE=FOUT,EXIST=EX)
	IF(EX) THEN
	write(*,*) 'FILE ALREADY EXISTS: 1- OVERWRITE IT,0- TRY ',
     +  'AGAIN WITH A NEW NAME'
	read(5,*) ID
		IF(ID.EQ.0) GO TO 103
		IF(ID.EQ.1) STAT='UNKNOWN'
	ENDIF
	OPEN(UNIT=IOUT,FILE=FOUT,STATUS=STAT,FORM='UNFORMATTED')
	DO K=1,NL+1
	write(IOUT) VT(K),VB(K),DZ(K),VST(K),VSB(K),RHOT(K),RHOB(K)
	ENDDO
	CLOSE(UNIT=IOUT)
	GO TO 135

! *** READ OLD MODEL FROM DISK ***

110	INQUIRE(FILE=inbound_model,EXIST=EX)
!      print *, 'readmmod.for,inbound_model=',inbound_model
        IF(EX) then
!		write(*,*) ''
!		write(*,*) 'readmmod,Default file immodpg.out exists.'
!		write(*,*) ''
!      call read_par_i4('0- use it , 1- No',idef)
!              if(idef.eq.1) 117
              go to 117
	 else
	       print *, 'Default file immodpg.out is missing!'
 !             if(idef.eq.1) go to 115
              go to 115

	end if

c
115     write(*,*) 'INPUT FILE NAME ?? '
	READ(5,'(A)') inbound_model
	INQUIRE(FILE=inbound_model,EXIST=EX)
	IF(.NOT.EX) THEN
	write(*,*)'FILE DOES NOT EXIST, TRY AGAIN WITH A NEW NAME'
	GO TO 115
	ENDIF
c
117	continue
	OPEN(UNIT=IIN,FILE=inbound_model,STATUS='OLD',FORM='UNFORMATTED')
	K=1
120     READ(IIN) VT(K),VB(K),DZ(K),VST(K),VSB(K),RHOT(K),RHOB(K)
	IF(VT(K).LT.0.) GO TO 125
	K=K+1
	GO TO 120
125	NL=K-1
c
	CLOSE(UNIT=IIN)
!   	write(*,*)'readmmod,FILE = ',inbound_model
	CALL WRIMOD2(NL,VT,VB,DZ,VST,VSB,RHOT,RHOB)
c
c *** MODIFICATIONS ***
c
	ID=0
!	Juan's modification for immodpg.for July 25 2020
!       write(*,*) 'readmmod.for L207'
!	CALL READ_PAR_I4('CHANGE THIS FILE? 1-YES 0-NO',ID)
!        write(*,*) 'readmmod.for L209 ID=', ID
!       FORCE NO READING OF MODEL
	ID=0
	IF(ID.NE.1) GO TO 135
127	write(*,*)'1-DELETE OR 2-INSERT AFTER LAYER,3- CHANGE LAYER '
	read(5,*) IMOD
	write(*,*)'LAYER NUMBER ?? '
	read(5,*) LNU
c
	IF(IMOD.EQ.1) THEN
	DO K=LNU,NL
   	VT(K)=VT(K+1)
	VB(K)=VB(K+1)
	DZ(K)=DZ(K+1)
	VST(K)=VST(K+1)
	VSB(K)=VSB(K+1)
	RHOT(K)=RHOT(K+1)
	RHOB(K)=RHOB(K+1)
	ENDDO
	NL=NL-1
	GO TO 130
	ENDIF
c
	I=LNU
	IF(IMOD.EQ.2) THEN
	K=NL+1
	I=LNU+1
57	CONTINUE
   	VT(K+1)=VT(K)
	VB(K+1)=VB(K)
	DZ(K+1)=DZ(K)
	VST(K+1)=VST(K)
	VSB(K+1)=VSB(K)
	RHOT(K+1)=RHOT(K)
	RHOB(K+1)=RHOB(K)
	K=K-1
	IF(K.GE.I) GO TO 57
	NL=NL+1
	VB(I)=VT(I+1)
	VSB(I)=VST(I+1)
	RHOB(I)=RHOT(I+1)
	VT(I)=VB(LNU)
	VST(I)=VSB(LNU)
	RHOT(I)=RHOB(LNU)
	ENDIF
	write(*,*)
	CALL READ_PAR_R4('VPTOP (KM/SEC) ?',VT(I))
	CALL READ_PAR_R4('VPBOTTOM (KM/SEC) ?',VB(I))
	CALL READ_PAR_R4('THICKNESS (KM)?',DZ(I))
	CALL READ_PAR_R4('VSTOP (KM/SEC) ?',VST(I))
	CALL READ_PAR_R4('VSBOTTOM (KM/SEC) ?',VSB(I))
	CALL READ_PAR_R4('TOP DENSITY (G/CC) ?',RHOT(I))
	CALL READ_PAR_R4('BOTTOM DENSITY (G/CC) ?',RHOB(I))
c
130	write(*,*)' MODIFIED MODEL ***'
	write(*,*)' '
	CALL WRIMOD2(NL,VT,VB,DZ,VST,VSB,RHOT,RHOB)
	write(*,*)' '
	write(*,*)'1- MORE MODIFICATIONS, 0- NO '
	read(5,*) ID
	IF(ID.EQ.1) GO TO 127
	IF(ID.EQ.0) GO TO 97
135	CONTINUE
	RETURN
	END
