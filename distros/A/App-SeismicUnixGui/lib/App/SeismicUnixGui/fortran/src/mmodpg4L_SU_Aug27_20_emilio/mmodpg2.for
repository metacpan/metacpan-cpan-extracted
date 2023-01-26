c
c Calculo de curvas camino-tiempo para modelos formados por una
c combinacion de capas planas homogeneas o con gradiente de
c velocidad constante. Fuente y receptor en 1ra capa; default
c es que ambos esten en superficie.
c
        integer   nlmax,npmax,npamax,ntrmax,nsmax,ntr,ns
        parameter (nlmax=50,npmax=60000,npamax=60000)
        parameter (ntrmax=1024,nsmax=8192)
        parameter (nxymax=1000)
        real      f(ntrmax,nsmax)
        real      fmin,fmax
        dimension IR(nlmax-1),VT(nlmax),VB(nlmax),DZ(nlmax)
        dimension VST(nlmax),VSB(nlmax),RHOT(nlmax),RHOB(nlmax)
        dimension va(2*nlmax),za(2*nlmax)
        dimension multin(nlmax)
        dimension ILA(npmax),P(npmax),X(npmax),T(npmax)
        dimension xa1(npamax),xa2(npamax),xa3(npamax),xa4(npamax)
        dimension xa5(npamax)
        dimension xdig(nxymax),tdig(nxymax)
        dimension xdigp(nxymax),tdigp(nxymax)
        dimension xdign(nxymax),tdign(nxymax),axdign(nxymax)
        character val,finxy*40
        logical   flag
c
c DEFAULT PARAMETERS
c
        sdepth = 0.0
        rdepth = 0.0
        pmin   = 0.0
        pmax   = 8.0
        dp     = 0.0006
        vmf    = 1./sqrt(3.)
        rv     = 2.0
        xmin   = -0.2
        xmax   = 0.3
        tmin   = 0.0
        tmax   = 0.2
        lch    = 1
        icolor = 0
        xinc   = 0.1
        iac    = 0
        iout   = 35
        datadx = 0.005
        datax1 = -0.185
c       datadt = 0.005
        datat1 = 0.0
        flag   = .false.
        idred  = 0
        idrdtr = 0
        idrxy  = 0
        clip   = 0.9
        idpof  = 0
c       psld   = 0.0
c
        do i=1,nlmax
                multin(i) = 1
        enddo
c
c ********  Program Message *********
c
        call messa
        write(*,*) ' '
        write(*,*) 'Modeling of Traveltime (T-X) Curves'
        write(*,*) ' '
        write(*,*) 'LDGO , 1984-1989'
        write(*,*) 'BOIGM, 1993'
        write(*,*) 'Depto. de Geofisica, U. de Chile, 1996-**'
        write(*,*) ' '
        write(*,*) 'Computations are carried out for a model consisting'
        write(*,*) 'of a mixture of horizontal constant velocity, and'
        write(*,*) 'constant vel. gradient layers.  Low velocity zones'
        write(*,*) 'can be included. Each layer is specified by its top'
        write(*,*) 'and bottom velocity.  Rays are traced using'
        write(*,*) 'equispaced ray parameters.'
        write(*,*) ' '
        write(*,*) 'Data traces are presented in wiggle plot mode'
        write(*,*) ' '
c
c Read digitized X-T pairs, and separate them by positive (p)
c and negative (n) offsets.
c
        call read_par_i4('1- Read digitized X-T pairs, 0- No',idrxy)
        if(idrxy.eq.1) then
c
           finxy = '???'
           call read_datxy(xdig,tdig,ndxy,finxy,21,1)
c
           ndxyp = 0
           ndxyn = 0
           do ixy = 1,ndxy
             if(xdig(ixy).ge.0.0) then
                     ndxyp = ndxyp + 1
                     xdigp(ndxyp) = xdig(ixy)
                     tdigp(ndxyp) = tdig(ixy)
             else
                     ndxyn = ndxyn + 1
                     xdign(ndxyn)  = xdig(ixy)
                     axdign(ndxyn) =-xdig(ixy)
                     tdign(ndxyn)  = tdig(ixy)
             endif

           enddo
           call read_par_i4('0- Consider abs(offsets), 1- No',idpof)
c
        endif
c
c Read data traces
c
        call read_par_i4('1- Read data traces, 0- No',idrdtr)
        if(idrdtr.eq.1) then
          call rdata(f,ntrmax,nsmax,ntr,ns,datadt,fmin,fmax)
c
c
          call read_par_r4('Time of 1st data sample (sec) ?',datat1)
          call read_par_r4('Dist. of trace 1 along line (km)?',datax1)
c         call read_par_r4('Perpendicular shot-line dist. (km)?',psld)
c         psld2 = psld * psld
          call read_par_r4('Dist. between geophones (km) ?',datadx)
          gain = 10 * datadx / fmax
          call read_par_r4('Gain for data?',gain)
c
        endif
c
15      continue
c
c ***** SOURCE AND RECEIVER DEPTH DEFINITION *****
c
        call read_par_r4('SOURCE DEPTH (KM) ?',SDEPTH)
        call read_par_r4('RECEIVER DEPTH (KM) ?',RDEPTH)
c
c **** PARAMETERS FOR THE X-T PLOT  ****
c
        write(*,*) 'TO DEFINE  PLOTTING AREA ENTER : '
        write(*,*) ' '
        rvinv=0.
        call read_par_r4('Reducing Velocity (km/s),(0-For none)',rv)
        if (rv.eq.0.) go to 40
        rvinv=1./rv
40      continue
        if(idrdtr.eq.1) then
        call read_par_i4('1-Traces are red. by this vel., 0-No',idred)
        endif
c
        call read_par_r4('MINIMUN DISTANCE (KM)?',xmin)
        call read_par_r4('MAXIMUN DISTANCE (KM)?',xmax)
        call read_par_r4('MINIMUN TIME (SEC)?',tmin)
        call read_par_r4('MAXIMUN TIME (SEC)?',tmax)
c **** RE-CHECK PARAMETERS ****
        ID=0
        call read_par_i4('1- RECHECK PARAMETERS,0- NO',ID)
        if(ID.eq.1) go to 15
c
c
        rvinvd = 0.0
        if(idred.eq.0) rvinvd = rvinv
c *******************
c *****    READ VELOCITY DEPTH MODEL  ******
c
        call READMMOD(VT,VB,DZ,VST,VSB,RHOT,RHOB,nl)
c
        call read_par_i4('Working layer number ?',lch)
                if(lch.lt.1)   lch = 1
                if(lch.gt.nl)  lch = nl
c
c ***************** Open X-T Window ****************
c
        call pgbegin(0,'?',1,1)
c       call pgpaper(12.0,8.5/11.0)
c       call pgpaper(17.0,0.6)
        call pgpaper(14.0,0.6)
        call pgask(flag)
************************************
c
10      continue
c
c Check for vt-vb too small.
c
        A3 = 0.001
c
        do 20 i = 1, nl
20      if(ABS(VT(I)-VB(I)).le.A3) vb(i) = vt(i)
c
c Reflections at the bottom of layers decided automatically
c based on velocity discontinuities
c
        do 34 I=1,nl-1
        IR(I)=0
34      if(ABS(VT(I+1)-VB(I)).GT.A3) IR(I)=1
        IR(nl) = 0  !** No reflection at the bottom of model
c
c *** COMPUTATIONS ***
c
        DZ1TEM=DZ(1)
        DZ(1)=DZ(1)-(SDEPTH+RDEPTH)/2. ! Correct only if 1rst layer
c                                        is a constant vel. layer. 
        call txpr(nl,VT,VB,DZ,PMIN,PMAX,DP,IR,multin,ntp,ILA,P,X,T)
        DZ(1)=DZ1TEM
c       write(*,*) 'total # of computed points ',ntp
c
c *** PLOTTING ***
c
55      continue
c       call pgvport(0.1,0.9,0.1,0.9)
        call pgvport(0.075,1.0,0.08,0.925)
        call pgwindow(xmin,xmax,tmax,tmin)
        call pgbox('BCTN',0.0,0,'BCTN',0.0,0)
        call pglabel('X(km)','T - X/Vred (s)',
c       call pglabel('X(km)','T - X/8.0 (seg)',
     +  'Curvas camino-tiempo (X-T), Ondas P, Modelo 1-D')
c     +  'Primary P-wave T-X Curves, 1-D Model')
c
        if(idrdtr.eq.1) then
                call pgsci(1)
                do j=1,ntr
                 xline = datax1 + (j-1) * datadx
c                 datax = sqrt(psld2 + xline*xline)
                 datax = xline
                 a4    = datax + clip * datadx
                 a5    = datax - clip * datadx
                 do i=1,ns
                   a3  = f(j,i)
                   xa1(i) = datax  +  gain * a3
                   if(xa1(i).gt.a4) xa1(i) = a4
                   if(xa1(i).lt.a5) xa1(i) = a5
                   xa3(i) = xa1(i)
                   if(a3.lt.0.0)    xa3(i) = datax
                   xa2(i) = datat1 + (i-1)*datadt - abs(datax)*rvinvd
                 enddo
c
                 call pgline(ns,xa1,xa2)
                 xa3(1)  = datax
                 xa3(ns) = datax
c pgsci(1) selecciona blanco (negro en papel) para rellenar trazas
c pgsci(3) relleno en verde
                 call pgsci(3)
                 call pgpolyev(ns,xa3,xa2)
c                call pgpoly(ns,xa3,xa2)
                 call pgsci(1)
                enddo
        endif
c
        do 140 j=1,lch
        nplj = 0
        do 120 i=1,ntp
c ** SELECT LAYER J **
        if(ABS(ILA(I)).NE.J) go to 120
        nplj = nplj+1
        xa1(nplj)  =   X(I)
        xa5(nplj)  =  -X(I)
        xa2(nplj)  =   T(I) - X(I) * rvinv !** RED. TIME
        xa3(nplj)  =   P(I)
        xa4(nplj)  =   T(I) - X(I) *  P(I) !** TAU
120     continue
        if(nplj.eq.0) go to 140
c
c ** PLOT LAYER J **
c
        icolor = icolor + 1
        if(icolor.gt.15) icolor = 1
        call pgsci(icolor)
c       call pgsci(3)
c
c ** X - T Plot **
c
        call pgline(nplj,xa1, xa2)
        call pgline(nplj,xa5, xa2)
c
c ** TAU - P Plot **
c
c       call gks$polyline(nplj, xa3, xa4)
c
140     continue
c
c Draw digitized X-T data
c
        if(idrxy.eq.1) then
c          Positive offsets branch
           if(ndxyp.gt.0) then
             do ixy = 1,ndxyp
               xa2(ixy) = tdigp(ixy) - xdigp(ixy) * rvinv
             enddo
             call pgsci(3)
c            call pgsci(2)
             call pgpoint(ndxyp,xdigp,xa2,9)
           endif
c          Negative offsets branch
           if(ndxyn.gt.0) then
             do ixy = 1,ndxyn 
               xa2(ixy) = tdign(ixy) - axdign(ixy) * rvinv
             enddo
             call pgsci(2)
             if(idpof.eq.0) then
               call pgpoint(ndxyn,axdign,xa2,9)
             else
               call pgpoint(ndxyn,xdign,xa2,9)
             endif
           endif
c
        endif
c
c Draw velocity model
c
c ****** descomentar para trabajo con OBS  ***
c       dz(1) = 2.0 * dz(1)
c ***********************
        a1 =  0.0
        a2 = -1.0
        do 145 i = 1,lch
                k = 2*i - 1
                va(k) = vt(i)
                if(vt(i).gt.a2) a2=vt(i)
                za(k) = a1
                va(k+1) = vb(i)
                if(vb(i).gt.a2) a2=vb(i)
                a1 = a1 + dz(i)
                za(k+1) = a1
145     continue
c ****** descomentar para trabajo con OBS  ***
c       dz(1) = dz(1)/2.0
c ***********************
c
        call pgsci(1)
        call pgvport(0.88,0.98,0.2,0.8)
        call pgwindow(0.0,a2,a1,0.0)
        call pgbox('BCTN',0.0,0,'BCNST',0.0,0)
        call pglabel('V(km/s)','Z(km)','')
c
c       call pgslw(5)
        call pgline(2*lch,va,za)
c       call pgslw(1)
c
150     continue
c
        write(*,*)''
        write(*,*)'*** CHANGE : *****************************'
        write(*,*)'0-  Working layer (Now is LAYER ',lch,')'
        write(*,500) VT(lch),VB(lch)
        write(*,502) DZ(lch)
        write(*,*)'5-  VTOP and overlying VBOT,  6-  VBOT and underlying
     + VTOP'
        write(*,504) DP
        write(*,503) xinc
        write(*,*)'******************************************'
        write(*,*)'8-  Zoom and move image, 11- Multiply all Velocities
     + by a constant'   
        write(*,*)'12- or larger to END'
c
        call read_par_i4('Option number ?',iac)
c
        if(iac.gt.11) go to 255
c
        if(iac.eq.7) then
                call read_par_r4('New increment (km or km/s) ??',xinc)
                go to 150
        endif
c
        if(iac.eq.8) then
                call pgzoom(xmin,xmax,tmin,tmax)
                icolor = 0
                call pgpage
                call pgsci(1)
                go to 55
        endif
c
c *** Options that require recompute X-T curves ***
c
        if(iac.eq.0) then
                lch = lch + 1
                call read_par_i4('Layer Number ??',lch)
                if(lch.lt.1)   lch = 1
                if(lch.gt.nl)  lch = nl
        endif
c
        if(iac.ge.1.and.iac.le.6) then
                write(*,*) ''
                write(*,*) 'RETURN to increase,  - to decrease'
                read(*,'(a)') val
c
                a1 = xinc
                if (val.eq.'-') a1 = -xinc
c
                if(iac.eq.1) VT(lch) = VT(lch) + a1
                if(iac.eq.2) VB(lch) = VB(lch) + a1
                if(iac.eq.3) DZ(lch) = DZ(lch) + a1
c
                if(iac.eq.4) then
                        VT(lch) = VT(lch) + a1
                        VB(lch) = VB(lch) + a1
                endif
c
                if(iac.eq.5) then
                        VT(lch) = VT(lch) + a1
                        if(lch.gt.1) VB(lch-1) = VB(lch-1) + a1
                endif
c
                if(iac.eq.6) then
                        if(lch.lt.nl) VT(lch+1) = VT(lch+1) + a1
                        VB(lch) = VB(lch) + a1
                endif
        endif
c
        if(iac.eq.9) then
                call read_par_r4('New gain ??',gain)
        endif
c
        if(iac.eq.10) then
                call read_par_r4('New dp (s/km) ??',dp)
        endif
c
        if(iac.eq.11) then
                call read_par_r4('Multiplicative constant ??',vmf)
                do i = 1,nl
                        VT(i) = vmf * VT(i)
                        VB(i) = vmf * VB(i)
                enddo 
        endif
c
c **************************
c
        icolor = 0
        call pgpage
        call pgsci(1)
        go to  10
c
255     continue
c
c write modified model to terminal
c
        write(*,*) ' '
        write(*,*) 'MODIFIED MODEL:'
        call WRIMOD2(nl,VT,VB,DZ,VST,VSB,RHOT,RHOB)
c
c write modified model to file mmodpg.out
c
        OPEN(UNIT=IOUT,FILE='mmodpg.out',STATUS='UNKNOWN',
     +  FORM='UNFORMATTED')
        do K=1,NL+1
                write(IOUT) VT(K),VB(K),DZ(K),
     +          VST(K),VSB(K),RHOT(K),RHOB(K)
        enddo
        CLOSE(UNIT=IOUT)
c
        write(*,*) 'This model has been written to file:'
        write(*,*) '***     mmodpg.out     ***'
c
        call pgend
500     format(' 1-  VTOP = ',f6.3,',            2-  VBOT = ',f6.3,' (km
     +/s)')
502     format(' 3-  DZ   = ',f7.4,' (km)',',      4-  VTOP and VBOT')
503     format(' 7-  Increment = ',f7.4,' (km or km/s)')
504     format(' 9-  Gain for data,            10- DP = ',f9.6,
     +' (s/km)')
        end
c
c ****************************************************
c
        SUBROUTINE rdata(f, m, n, ntr, ns, datadt, fmin, fmax)
        INTEGER m,n,ntr,ns,idtusec
        REAL f(m,m), fmin, fmax
        CHARACTER*40 FIN
        LOGICAL EX
c
c Read data parameters
c
        iin=26
        OPEN(UNIT=iin,FILE='parmmod',STATUS='OLD')
        read(iin,*) ntr,ns,idtusec
        close(iin)
        datadt = float(idtusec) * 1e-6
c
c115    write(*,*) 'INPUT DATA FILE NAME ?? '
c	READ(5,'(A)') FIN
c       INQUIRE(FILE=FIN,EXIST=EX)
c	if(.NOT.EX) then
c	write(*,*)'FILE DOES NOT EXIST, TRY AGAIN WITH A NEW NAME'
c	go to 115
c	endif
c
c	OPEN(UNIT=iin,FILE=FIN,STATUS='OLD',FORM='UNFORMATTED')
c
c Read data File
c
        OPEN(UNIT=iin,FILE='datammod',STATUS='OLD',FORM='UNFORMATTED')
        k=1
120     READ(iin) (f(k,i), i=1,ns)
        if(k.GE.ntr) go to 125
        k=k+1
        go to 120
125     CLOSE(UNIT=iin)
c
      fmin = 1e30
      fmax = -1e30
      do 20 i=1,ntr
         do 10 j=1,ns
            fmin = min(f(i,j),fmin)
            fmax = max(f(i,j),fmax)
 10      continue
 20   continue
c
        write(*,*) 'Data min, max  = ',fmin,fmax
        write(*,*)
c
      END
c
c ************************************************
c
        subroutine read_datxy(x,y,n,fin,iin,iwrit)
c
c Reads file containing (x,y) pairs and an arbitrary number of comment lines
c in between.  The (x,y) pairs are returned in arrays x and y. The
c comment lines are written on the terminal.
c
c n     = number of (x,y) pairs in the file (output).
c
c fin   = Default input file name (input)
c iin   = reading input unit (input).
c iwrit = if iwrit.eq.1, (x,y) pairs are written on screen (input).  
c
        dimension x(*),y(*)
        character*40 fin
        character*40 comment
        LOGICAL EX
c
c  ********* read input file *********
c
c Check for default file "fin".  If file does not exist, then ask for
c a file name
c
c       write(*,*) fin
        go to 117
115     write(*,*) 'Input File Name ?? '
        READ(*,'(A)') fin
117     INQUIRE(FILE=fin,EXIST=EX)
        IF(.NOT.EX) THEN
        write(*,*) 'There is no trace defined'
        GO TO 115
        ENDIF
        OPEN(UNIT=iin,FILE=fin,STATUS='OLD')
c
        n = 1
        write(*,*)
120     continue
        READ(iin,'(a)',end=170,err = 150) comment
        read(comment,*,err = 150) xa,ya
        x(n) = xa
        y(n) = ya
        n = n + 1
        go to 120
150     continue
        write(*,'(a)') comment
        go to 120
170     continue
        close(iin)
        n = n - 1
c ************************************************************
        if(n.ge.1) then
           if(iwrit.eq.1) then
                write(*,*) '** Digitized traveltime data ** '
                write(*,*) ' '
                write(*,*) '            X(km)          T(sec)'
                write(*,*) ' '
                do 180 i = 1,n
180             write(*,300) i,x(i),y(i)
                write(*,*) ' '
           endif
        else
        write(*,*) '* There is no line containing data in this file *'
        endif
300     format(i5,2f15.6)
        return
        end
c ******************************************
