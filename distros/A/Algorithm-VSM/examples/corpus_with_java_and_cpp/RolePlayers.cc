// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 16  Multiple Inheritance In C++
//
// Section:     Section 16.10  Using Role-Playing Classes
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//RolePlayers.cc

#include "MI_Utilities.h"

///////////////////  incomplete def of class Role  ////////////////////      
class Role;

//////////////////////////  class Employee  ///////////////////////////
class Employee {
protected:
    string name;
    string address;
    EducationLevel education;
    PeopleSkill pSkill;   
    Leadership leadership;
    vector<Role*> allRoles;  
    Role* activeRole;
public:
    Employee( string nam,
              string add,
              EducationLevel edLevel )
        :     name( nam ),
              address( add ),
              education( edLevel ),
              pSkill( pUnknown ),
              leadership( lUnknown ),
              allRoles( vector<Role*>() ),
              activeRole( 0 )
    {}
    Employee( const Employee& other );
    void setActiveRole( Role* role );
    Role* getActiveRole() const { return activeRole; }
    void addToRoles( Role* newRole );
    void removeRole( Role* role );
    void removeAllRoles();
    void setPeopleSkill( PeopleSkill skill ) { pSkill = skill; }
    string getName() const { return name; }
    string getAddress() const { return address; }
    void setEducationLevel(EducationLevel eduLvl) {education = eduLvl;}
    EducationLevel getEducationLevel() const { return education; }
    Leadership getLeadership() const { return leadership; }
    void setLeadership( Leadership lead ) { leadership = lead; }
    void print();        // needs role definitions
    ~Employee() {}       // see text for why this is do-nothing   //(A)
};


/////////////////////////////  class Role  ////////////////////////////
class Role {
protected:
    string roleName;
    int roleExperience;           // in years
public:
    Role() {}
    Role( string arole, int experience )
        :  roleName( arole ),
           roleExperience( experience )
        {}
    Role( const Role& other ) 
        :  roleName( other.roleName ),
           roleExperience( other.roleExperience )
        {}
    string getRoleName() const { return roleName; }
    void setRoleName( string name ) { roleName = name; }
    int getRoleExperience() const { return roleExperience; }
    void setRoleExperience( int yy ) { roleExperience = yy; }
    virtual bool operator==( const Role& role ) {
        return ( roleName == role.roleName ) ? true : false;
    }
    void printRoleExperience() const {
        cout << "Years in this role: " << roleExperience << endl;
    }
    virtual void print() const {};
    virtual ~Role() {};
};

////////////  Employee member functions that need Role defs ///////////
Employee::Employee( const Employee& other )
    : name( other.name ),
      address( other.address ),
      education( other.education ),
      pSkill( other.pSkill ),
      leadership( other.leadership ),
      allRoles( other.allRoles ),
      activeRole( other.activeRole )
{}
void Employee::addToRoles(Role* newRole){allRoles.push_back(newRole);}
void Employee::removeRole( Role* role ) {
    vector<Role*>::iterator iter = allRoles.begin();
    while ( iter != allRoles.end() ) {
        if ( *iter == role ) {
            allRoles.erase( iter );
        }
        iter++;
    }
}
void Employee::removeAllRoles() { allRoles = vector<Role*>(); }
void Employee::setActiveRole( Role* role ) { activeRole = role; }
void Employee::print() {
    cout << name << endl;
    cout << address << endl;
    cout << EducationLevels[ education ] << endl;
    cout << "People skill: " << PeopleSkills[ (int) pSkill ] << endl;
    cout << "Leadership quality:" << LeaderQualities[(int) leadership];    
    cout << endl;
    if ( activeRole != 0 )
        cout << "ACTIVE ROLE: " << activeRole->getRoleName() << endl;
    if ( allRoles.size() != 0 ) {
        cout << "LIST OF ALL ALLOWABLE ROLES: " << endl;
        vector<Role*>::iterator iter = allRoles.begin();
        while ( iter != allRoles.end() ) {
            cout << (*iter)->getRoleName() << endl;
            (*iter++)->printRoleExperience();
        }
    }
}

////////////////  mixin  class ManagerType (abstract)  ////////////////
class ManagerType {
protected:
    virtual double productivityGainYtoY() = 0;
    virtual bool computeEmployeeSatisfaction() = 0;
};

//////////////////////  class Manager (IsA Role)  /////////////////////
class Manager : public Role, public ManagerType {
    Department dept;
public:
    Manager() {}         // Needed by the ExecutiveManager constructor
    Manager( string roleName ) : Role( roleName, 0 ) {}
    Manager( Department aDept ) 
        : Role( "Manager of " + aDept.getName(), 0 ), dept( aDept ) {}
    double productivityGainYtoY() {  
        int lastProd = dept.getProductionLastYear();
        int prevProd = dept.getProductionPreviousYear();
        return 100 * ( lastProd - prevProd ) / (double) prevProd;
    }
    bool computeEmployeeSatisfaction() { return true; }
    void print() {
        printRoleExperience();
        dept.print();
    }
    ~Manager() {}
};

////////////////////  class ExecutiveManager  ////////////////////
// An ExecutiveManager supervises more than one department
class ExecutiveManager : public Manager {
    short level;
    vector<Department> departments;
public:
    ExecutiveManager( short lvl ) 
        : Manager( "Executive Manager" ),
          level( lvl ) { departments = vector<Department>(); }
    void addDepartment(Department dept){departments.push_back( dept );}
    void setLevel( int lvl ) { level = lvl; }
    // overrides Manager's productivityGainYtoY():
    double productivityGainYtoY() {  
        double gain = 0.0;
        vector<Department>::iterator iter = departments.begin();
        while ( iter != departments.end() ) {
            int lastProd = iter->getProductionLastYear();
            int prevProd = iter->getProductionPreviousYear();
            gain += ( lastProd - prevProd ) / (double) prevProd;
        }
        return gain/departments.size();
    }
    void print() {
        printRoleExperience();
        if ( departments.size() != 0 ) {
            cout << "Departments supervised: " << endl;
            vector<Department>::iterator iter = departments.begin();
            while ( iter != departments.end() ) 
            iter++->print();
        }
    }
    ~ExecutiveManager() {};
};

//////////////////  mixin class SalesType (abstract)  /////////////////
class SalesType {
protected:
    virtual double salesVolume() = 0;
    virtual double productivityGainYtoY() = 0;
};

/////////////////////////  class SalesPerson  /////////////////////////
class SalesPerson : public Role, public SalesType {
    double salesVolLastYear;
    double salesVolPrevYear;
public:
    SalesPerson( string rolename ) : Role( rolename, 0 ) {}
    SalesPerson() : Role( "Sales Person", 0 ), salesVolLastYear( 0 ),
          salesVolPrevYear( 0 ) {}
    void setSalesVolLastYear(double sales){ salesVolLastYear = sales; }
    void setSalesVolPrevYear(double sales){ salesVolPrevYear = sales; }
    double salesVolume() { return salesVolLastYear; }
    double productivityGainYtoY() {
        return 100 * (salesVolLastYear 
                 - salesVolPrevYear) / salesVolPrevYear;
    }
    void print() {
        cout << "Sales Department" << endl;
        printRoleExperience();
    }  
    ~SalesPerson() {}
};

//////////////////////////  class SalesManager  ///////////////////////
class SalesManager : public SalesPerson, public ManagerType {
    vector<SalesPerson*> sellersSupervised;
public:
    SalesManager()
        : SalesPerson( "Sales Manager" ),
          sellersSupervised( vector<SalesPerson*>() )
        {}
    // overrides SalesPerson's productivityGainYtoY():
    double productivityGainYtoY(){  
        double gain = 0.0;
        vector<SalesPerson*>::iterator iter 
                      = sellersSupervised.begin();
        while ( iter != sellersSupervised.end() ) {
            gain += (*iter++)->productivityGainYtoY();
        }
        return gain/sellersSupervised.size();
    }
    void print() {
        printRoleExperience();
        if ( sellersSupervised.size() != 0 ) {
            cout << "Sales Persons supervised: " << endl;
            vector<SalesPerson*>::iterator iter 
                        = sellersSupervised.begin();
            while ( iter != sellersSupervised.end() ) 
                (*iter++)->print();
        }
    }
    ~SalesManager() {} 
};

///////////////////  special function that uses RTTI //////////////////
bool checkReadyForPromotion( Employee* e ) {                      //(B)
    Role* r = e->getActiveRole();
    Manager* m = dynamic_cast<Manager*>( r );
    if ( m != 0 ) {
        // add additional promotion criteria to the following test
        // as necessary (left as an exercise to the reader)
        if ( m->getRoleExperience() >= MinYearsForPromotion ) {
            cout << "yes, ready for promotion in the active role\n";
            return true;
        }
        else {
            cout << "Not ready for promotion in the active role\n";
            return false;
        }
    }
    SalesPerson* s = dynamic_cast<SalesPerson*>( r );
    if ( s != 0 ) {
        if ( s->productivityGainYtoY() > 50 ) {
            cout << "yes, ready for promotion in the active role\n"; 
            return true;
        }
        else {
            cout << "Not ready for promotion in the active role\n";
            return false;
        }
    }
    else {
        cout << "Unable to determine if ready for promotion\n";
        return false;
    }
}

/*****
class bad_cast {};                                                //(C)

bool checkReadyForPromotion( Employee* e ) {
  Role& role_ref = *( e->getActiveRole() );

  try {
    Manager& m_ref = dynamic_cast<Manager&>( role_ref );
    if ( m_ref.getRoleExperience() >= MinYearsForPromotion ) {
      cout << "yes, ready for promotion in the active role\n" 
      return true;
    }
    else 
        cout << "No, not ready for promotion in the active role\n";
  } catch( bad_cast& b ) {
    cout << "Unable to determine if ready for promotion" << endl; 
    return false;
  }
}
*****/ 

////////////////////////////////  main  ///////////////////////////////
int main()
{
    Department d1( "Design" );
    Department d2( "Manufacturing" );
    Department d3( "Development" );
 
    cout << "TEST 1: " << endl;                                   //(D)

    Employee* emp1 = new Employee("Zippy Zester","Zeetown",HighSchool); 

    Role* role1 = new Manager( d1 );
    Role* role2 = new Manager( d2 );
 
    role1->setRoleExperience( 2 );
    role2->setRoleExperience( 12 );

    emp1->addToRoles( role1 );
    emp1->addToRoles( role2 );
    emp1->setActiveRole( role2 );
    emp1->print();                                                //(E)

    checkReadyForPromotion( emp1 );                               //(F)
    cout << endl << endl;


    cout << "TEST 2: " << endl;                                   //(G)

    Employee* emp2 = new Employee("Deny Deamon","Deensville",College);
    emp2->setPeopleSkill( Friendly );
    emp2->setLeadership( CanLeadLargeGroups );
    Role* role3 = new Manager( d1 );
    Role* role4 = new Manager( d2 );
    role3->setRoleExperience( 23 );
    role4->setRoleExperience( 7 );

    emp2->addToRoles( role3 );
    emp2->addToRoles( role4 );
 
    Role* role5 = new SalesPerson();
    role5->setRoleExperience(18);
    SalesPerson* sp = static_cast<SalesPerson*>( role5 );
    sp->setSalesVolLastYear( 200 );
    sp->setSalesVolPrevYear( 100 );
    emp2->addToRoles( role5 );
    emp2->setActiveRole( role5 );
    emp2->print();                                                //(H)

    checkReadyForPromotion( emp2 );                               //(I)

    delete emp1;
    delete emp2;

    delete role1;
    delete role2;
    delete role3;
    delete role4;
    delete role5;

    return 0;
}